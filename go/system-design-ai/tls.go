//go:build ignore

package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/hex"
	"fmt"
	"math/big"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): TLS 1.3 HANDSHAKE, PKI & MUTUAL TLS (mTLS)
================================================================================
Key Topics Covered:
1. TLS 1.2 vs TLS 1.3 Architecture:
   - Handshake RTT: TLS 1.2 requires 2-RTT; TLS 1.3 achieves 1-RTT (and 0-RTT resumption).
   - Cryptographic Hygiene: Deprecated RSA key exchange; mandates Ephemeral Diffie-Hellman (ECDHE)
     for Perfect Forward Secrecy (PFS). If private key leaks in future, past traffic cannot be decrypted!
2. Public Key Infrastructure (PKI) Certificate Hierarchy:
   - Root CA (offline, air-gapped) -> Intermediate CA -> Leaf Server Certificate.
3. Mutual TLS (mTLS) in Zero-Trust Service Meshes:
   - Both Client and Server verify each other's x509 certificates for East-West microservice calls.
================================================================================
*/

// GenerateSelfSignedCert generates a valid in-memory x509 certificate for simulation
func GenerateTestCA(commonName string) (*x509.Certificate, *ecdsa.PrivateKey, error) {
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, nil, err
	}

	template := &x509.Certificate{
		SerialNumber: big.NewInt(time.Now().UnixNano()),
		Subject: pkix.Name{
			CommonName:   commonName,
			Organization: []string{"Acme Cloud Root CA"},
		},
		NotBefore:             time.Now(),
		NotAfter:              time.Now().Add(24 * time.Hour),
		IsCA:                  true,
		KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageDigitalSignature,
		BasicConstraintsValid: true,
	}

	certDER, err := x509.CreateCertificate(rand.Reader, template, template, &priv.PublicKey, priv)
	if err != nil {
		return nil, nil, err
	}

	cert, err := x509.ParseCertificate(certDER)
	return cert, priv, err
}

// IssueLeafCertificate issues a server or client certificate signed by a CA
func IssueLeafCertificate(commonName string, isClient bool, caCert *x509.Certificate, caPriv *ecdsa.PrivateKey) (*x509.Certificate, *ecdsa.PrivateKey, error) {
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, nil, err
	}

	extKeyUsage := []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth}
	if isClient {
		extKeyUsage = []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth}
	}

	template := &x509.Certificate{
		SerialNumber: big.NewInt(time.Now().UnixNano()),
		Subject: pkix.Name{
			CommonName:   commonName,
			Organization: []string{"Acme Internal Mesh"},
		},
		NotBefore:    time.Now(),
		NotAfter:     time.Now().Add(12 * time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature | x509.KeyUsageKeyEncipherment,
		ExtKeyUsage:  extKeyUsage,
		DNSNames:     []string{commonName},
	}

	certDER, err := x509.CreateCertificate(rand.Reader, template, caCert, &priv.PublicKey, caPriv)
	if err != nil {
		return nil, nil, err
	}

	cert, err := x509.ParseCertificate(certDER)
	return cert, priv, err
}

// SimulateTLS13Handshake performs ECDHE key exchange simulation
func SimulateTLS13Handshake() (sharedSecretHex string) {
	// 1. Client generates ephemeral P-256 private/public key
	clientPriv, _ := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)

	// 2. Server generates ephemeral P-256 private/public key
	serverPriv, _ := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)

	// 3. Diffie-Hellman computation:
	// Client computes: clientPriv * serverPub
	// Server computes: serverPriv * clientPub
	// Both arrive at the exact same shared secret point (x, y)!
	sharedX, _ := elliptic.P256().ScalarMult(serverPriv.PublicKey.X, serverPriv.PublicKey.Y, clientPriv.D.Bytes())

	// HKDF / SHA-256 derivation to obtain symmetric AES-256-GCM session key
	hash := sha256.Sum256(sharedX.Bytes())
	return hex.EncodeToString(hash[:])
}

func main() {
	fmt.Println("=== SD3 TLS 1.3: 1-RTT Handshake, PKI Chain & mTLS Verification ===")

	// 1. Build PKI Certificate Hierarchy
	fmt.Println("\n[1] Building Public Key Infrastructure (PKI) Chain:")
	rootCA, rootPriv, err := GenerateTestCA("Acme Corporate Root CA")
	if err != nil {
		panic(err)
	}
	fmt.Printf("  Root CA Created: %s (Serial: %s)\n", rootCA.Subject.CommonName, rootCA.SerialNumber.String())

	// Issue Server Leaf Certificate
	serverCert, _, err := IssueLeafCertificate("order-service.internal", false, rootCA, rootPriv)
	if err != nil {
		panic(err)
	}
	fmt.Printf("  Server Cert Issued: %s (Signed by %s)\n", serverCert.Subject.CommonName, rootCA.Subject.CommonName)

	// Issue Client Leaf Certificate (for mTLS)
	clientCert, _, err := IssueLeafCertificate("payment-service-client.internal", true, rootCA, rootPriv)
	if err != nil {
		panic(err)
	}
	fmt.Printf("  Client Cert Issued: %s (for mTLS Mutual Auth)\n", clientCert.Subject.CommonName)

	// 2. Validate Certificate Chain
	fmt.Println("\n[2] Validating PKI Trust Chain:")
	roots := x509.NewCertPool()
	roots.AddCert(rootCA)

	opts := x509.VerifyOptions{
		Roots:   roots,
		DNSName: "order-service.internal",
	}

	if _, err := serverCert.Verify(opts); err != nil {
		fmt.Printf("  Verification FAILED: %v\n", err)
	} else {
		fmt.Println("  -> Cryptographic Verification PASSED: Server certificate is trusted by Root CA!")
	}

	// 3. Simulate TLS 1.3 1-RTT ECDHE Handshake
	fmt.Println("\n[3] Simulating TLS 1.3 1-RTT ECDHE (Ephemeral Diffie-Hellman):")
	start := time.Now()
	sessionKey := SimulateTLS13Handshake()
	elapsed := time.Since(start)

	fmt.Printf("  Computed Shared Symmetric Session Key (AES-256-GCM): %s...\n", sessionKey[:32])
	fmt.Printf("  Handshake Completed in: %v\n", elapsed)
	fmt.Println("  Perfect Forward Secrecy (PFS): Ephemeral keys discarded after session ends.")

	fmt.Println("\n[SD3 Takeaway]: TLS 1.3 reduces latency from 2-RTT to 1-RTT; mTLS cryptographically authenticates east-west microservices.")
}
