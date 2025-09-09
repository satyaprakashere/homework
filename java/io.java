import java.io.*;

void main() throws IOException {
  BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
  StringTokenizer st = new StringTokenizer(br.readLine());

  int n = Integer.parseInt(st.nextToken());
  int k = Integer.parseInt(st.nextToken());
  System.out.println("n =" + n + " and k =" + k);
}
