# ICT2216 Practical Lab Test — Student 2400620

This repository answers Questions 1-9 with a small Node.js application and a
single Docker Compose stack.

## Endpoints and accounts

| Service | URL | Username | Password |
|---|---|---|---|
| HTTPS web application | <https://127.0.0.1> | Not required | Not required |
| HTTP test endpoint | <http://127.0.0.1:8080> | Not required | Not required |
| Local Gitea server | <http://127.0.0.1:3001> | `admin` | `2400620@SIT.singaporetech.edu.sg` |
| SonarQube | <http://127.0.0.1:9000> | `admin` | `2400620@SIT.singaporetech.edu.sg` |

The clarified password for every `admin` account is
`2400620@SIT.singaporetech.edu.sg`. The Git commit email remains the lowercase
identity required by Question 3: `2400620@sit.singaporetech.edu.sg`.

## Run and provision

After extracting `2400620.zip`, run the exact required command from the
extracted directory:

```bash
sudo docker-compose up
```

No second setup command is required. Compose builds missing images, generates
the HTTPS certificate, provisions the Gitea and SonarQube `admin` accounts,
commits the full source and Actions workflow into Gitea, runs unit coverage,
submits the SonarQube scan, and fails the scanner unless bugs, vulnerabilities,
and security hotspots are all zero. Leave the command running while marking.
Use `Ctrl+C` only when finished.

On Windows PowerShell, where `sudo` is not used, the equivalent command is
`docker-compose up`.

The `cert-generator` service creates a self-signed RSA certificate with
`subjectAltName=IP:127.0.0.1`. The browser will warn because it is self-signed.
Verify the endpoints:

```powershell
curl.exe -k https://127.0.0.1/health
curl.exe http://127.0.0.1:8080/health
curl.exe http://127.0.0.1:3001/api/healthz
curl.exe http://127.0.0.1:9000/api/system/status
docker compose ps
```

## Security and application behaviour

- Frontend and backend both enforce 2-100 characters and an ASCII allowlist.
- The backend is the security boundary; invalid, repeated, SQL-injection-like,
  or XSS-like input is rejected and redirected to a fresh home page.
- Valid data is HTML-encoded before display.
- MySQL writes use a parameterized query.
- Valid searches are logged with a UTC timestamp in table `` `2400620` ``.
- Helmet supplies Content Security Policy and other browser security headers.
- Nginx limits request size and rate and permits TLS 1.2/1.3 only.
- Internal errors return a generic message.

Check stored data:

```powershell
docker compose exec -T db mysql `
  -uadmin '-p2400620@SIT.singaporetech.edu.sg' searchdb `
  -e 'SELECT id, search_query, query_time FROM `2400620`;'
```

## Tests and security scanning

Local checks:

```powershell
npm ci
npm run lint
npm run test:coverage
npm run test:integration
npm audit --audit-level=high
```

The workflow at `.github/workflows/secure-ci.yml` runs:

1. unit and HTTP integration tests;
2. Selenium Chrome UI testing over `http://127.0.0.1:8080`;
3. npm audit and OWASP Dependency-Check;
4. ESLint with `eslint-plugin-security`, with SARIF artifact/upload.

The initial `sudo docker-compose up` performs the local SonarQube analysis
without requiring a host-installed scanner. It creates a temporary analysis
token, waits for the quality gate, and fails unless unresolved bugs,
vulnerabilities, and to-review security hotspots are all zero.

## Git identity and local server

```powershell
git config user.name "ETHAN TAN E-XIN"
git config user.email "2400620@sit.singaporetech.edu.sg"
git remote add origin http://127.0.0.1:3001/admin/ict2216-practical-2400620.git
git push -u origin main
```

## Requirement mapping

- Q1-Q2: `docker-compose.yml`, `nginx/`, `web`, `db`.
- Q3 and Q4L: Gitea service, local Git identity, committed and pushed repo.
- Q4a-k: `src/`, `public/`, `db/init.sql`.
- Q5-Q6: `.github/workflows/secure-ci.yml`.
- Q7-Q9: SonarQube services and `scripts/scan-sonar.ps1`.

## References

- OWASP Top 10 Proactive Controls 2024, C3:
  <https://top10proactive.owasp.org/the-top-10/c3-validate-input-and-handle-exceptions/>
- OWASP Input Validation Cheat Sheet:
  <https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html>
- SonarScanner CLI documentation:
  <https://docs.sonarsource.com/sonarqube-community-build/analyzing-source-code/scanners/sonarscanner>
