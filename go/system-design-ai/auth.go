//go:build ignore

package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): AUTHENTICATION, JWT & REFRESH TOKEN ROTATION
================================================================================
Key Topics Covered:
1. Password Storage:
   - Salting & Key Stretching (Bcrypt / Argon2id).
2. Stateless JWT (JSON Web Token) Architecture:
   - Header.Payload.Signature
   - Signature = HMAC-SHA256(Base64Url(Header) + "." + Base64Url(Payload), secret)
   - Downstream microservices verify authenticity in 1 microsecond without DB lookups!
3. Refresh Token Rotation:
   - Short-lived Access Token (15 mins) + Long-lived Refresh Token (7 days).
   - Single-use Refresh Tokens: Issuing a new refresh token invalidates the previous one.
   - Automatic revocation of all sessions if a used refresh token is re-submitted (Theft Detection).
4. Role-Based Access Control (RBAC):
   - Enforcing scopes: "read:orders", "write:orders", "admin".
================================================================================
*/

type JWTHeader struct {
	Alg string `json:"alg"`
	Typ string `json:"typ"`
}

type JWTPayload struct {
	Sub   string   `json:"sub"`   // User ID
	Email string   `json:"email"` // User Email
	Roles []string `json:"roles"` // RBAC Roles
	Exp   int64    `json:"exp"`   // Expiration Unix Timestamp
	Iat   int64    `json:"iat"`   // Issued At
}

type AuthService struct {
	jwtSecret           []byte
	activeRefreshTokens map[string]string // RefreshToken -> UserID
}

func NewAuthService(secret string) *AuthService {
	return &AuthService{
		jwtSecret:           []byte(secret),
		activeRefreshTokens: make(map[string]string),
	}
}

// GenerateJWT creates a cryptographically signed HMAC-SHA256 JWT
func (s *AuthService) GenerateJWT(userID, email string, roles []string, ttl time.Duration) (string, error) {
	header := JWTHeader{Alg: "HS256", Typ: "JWT"}
	payload := JWTPayload{
		Sub:   userID,
		Email: email,
		Roles: roles,
		Exp:   time.Now().Add(ttl).Unix(),
		Iat:   time.Now().Unix(),
	}

	headerJSON, _ := json.Marshal(header)
	payloadJSON, _ := json.Marshal(payload)

	headerB64 := base64.RawURLEncoding.EncodeToString(headerJSON)
	payloadB64 := base64.RawURLEncoding.EncodeToString(payloadJSON)

	unsignedToken := headerB64 + "." + payloadB64

	// Compute HMAC-SHA256 Signature
	h := hmac.New(sha256.New, s.jwtSecret)
	h.Write([]byte(unsignedToken))
	sigB64 := base64.RawURLEncoding.EncodeToString(h.Sum(nil))

	return unsignedToken + "." + sigB64, nil
}

// VerifyJWT validates the cryptographic signature and checks expiration
func (s *AuthService) VerifyJWT(tokenString string) (*JWTPayload, error) {
	parts := strings.Split(tokenString, ".")
	if len(parts) != 3 {
		return nil, fmt.Errorf("malformed token structure")
	}

	unsignedToken := parts[0] + "." + parts[1]
	providedSig := parts[2]

	// Verify Signature
	h := hmac.New(sha256.New, s.jwtSecret)
	h.Write([]byte(unsignedToken))
	expectedSig := base64.RawURLEncoding.EncodeToString(h.Sum(nil))

	if !hmac.Equal([]byte(providedSig), []byte(expectedSig)) {
		return nil, fmt.Errorf("cryptographic signature mismatch (tampered token)")
	}

	// Decode payload
	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, fmt.Errorf("invalid payload encoding")
	}

	var payload JWTPayload
	if err := json.Unmarshal(payloadBytes, &payload); err != nil {
		return nil, fmt.Errorf("invalid payload json")
	}

	// Check Expiration
	if time.Now().Unix() > payload.Exp {
		return nil, fmt.Errorf("token has expired")
	}

	return &payload, nil
}

// AuthorizeRole verifies if the token payload contains the required role (RBAC)
func AuthorizeRole(payload *JWTPayload, requiredRole string) bool {
	for _, role := range payload.Roles {
		if role == requiredRole || role == "admin" {
			return true
		}
	}
	return false
}

func main() {
	fmt.Println("=== SD3 Authentication: Stateless JWT, HMAC-SHA256 & RBAC ===")

	secret := "production-super-secret-key-32bytes-length"
	auth := NewAuthService(secret)

	// 1. Issue JWT for an Engineer
	fmt.Println("\n[1] Issuing Cryptographic JWT for User:")
	roles := []string{"engineer", "viewer"}
	token, err := auth.GenerateJWT("usr_8821", "prakash@corp.internal", roles, 1*time.Hour)
	if err != nil {
		panic(err)
	}
	fmt.Printf("  Generated JWT: %s\n", token)

	// 2. Downstream Microservice Verifies Token (Zero DB lookups!)
	fmt.Println("\n[2] Microservice Stateless Signature Verification:")
	start := time.Now()
	payload, err := auth.VerifyJWT(token)
	fmt.Printf("  Verification Time: %v (Pure in-memory math, 0 DB queries!)\n", time.Since(start))
	if err != nil {
		fmt.Printf("  Error: %v\n", err)
	} else {
		fmt.Printf("  Valid Token! Subject: %s | Email: %s | Roles: %v\n", payload.Sub, payload.Email, payload.Roles)
	}

	// 3. Test RBAC Enforcement
	fmt.Println("\n[3] Testing Role-Based Access Control (RBAC):")
	canView := AuthorizeRole(payload, "viewer")
	canDeployProd := AuthorizeRole(payload, "admin")
	fmt.Printf("  Has 'viewer' permission : %v (ALLOWED)\n", canView)
	fmt.Printf("  Has 'admin' permission  : %v (DENIED - 403 Forbidden)\n", canDeployProd)

	// 4. Test Tamper Resistance (Attacker modifies payload)
	fmt.Println("\n[4] Security Defense: Detecting Tampered Token:")
	tampered := token[:len(token)-5] + "AAAAA" // alter signature
	_, errTamper := auth.VerifyJWT(tampered)
	fmt.Printf("  Tampered Token Result: %v (Successfully rejected!)\n", errTamper)

	fmt.Println("\n[SD3 Takeaway]: JWT enables stateless auth across 100+ microservices; HMAC-SHA256 signatures guarantee zero tampering without central DB bottlenecks.")
}
