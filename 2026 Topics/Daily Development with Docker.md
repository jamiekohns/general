# Daily Development with Docker (and Lasers)

## Docker
Docker is my favorite containerization suite, though I initially started with Kubernetes in 2018 
(at the Northeast PHP conference).

Other container options:
- Kubernetes
- Podman (Open Container Initiative)
- Dev Containers (devcontainer)

### Why Containerization?

**The Problem with Traditional Development:**
- **XAMPP/WAMP/MAMP**: Single versions of PHP, MySQL, Apache - what happens when Project A needs PHP 8.1 and Project B needs PHP 8.3?
- **Direct Server Development**: Changes break production, no local testing, slow feedback loops
- **Local Installations**: Pollutes your host OS with dependencies, difficult to clean up, "works on my machine" syndrome

**Technical Benefits of Containers:**

1. **Environment Consistency**
   - Identical development, staging, and production environments*
   - Eliminates "works on my machine" issues
   - Dockerfile serves as infrastructure documentation

2. **Isolation & Multi-Version Support**
   - Run PHP 7.4, 8.1, 8.3 simultaneously for different projects
   - Each project gets its own MySQL, Redis, Elasticsearch versions
   - No conflicts between project dependencies

3. **Clean Host System**
   - No need to install PHP, MySQL, Redis, etc. directly on your machine
   - Containers are ephemeral - delete and recreate without trace
   - Easy to start fresh when things get messy

4. **Reproducibility**
   - New developer setup: `docker-compose up` (not a 3-page wiki)
   - Infrastructure as code - version controlled with your application
   - Exact same environment 6 months or 2 years later

5. **Production Parity**
   - Develop on the same OS, same versions as production*
   - Catch environment-specific bugs early
   - Deployment becomes simpler (same container, different host)*

6. **Rapid Experimentation**
   - Test a new PHP version? Change one line in Dockerfile
   - Try PostgreSQL instead of MySQL? Swap the service
   - Roll back instantly if something breaks

### How does Docker work

## Laravel: Sail

## Laravel: Pure PHP

## Coder

### Copilot Chat
`code-server` is a port of VS Code, so it includes the side-panel for interacting with the `Github Copilot Chat`
extension, but the extension is not installed, nor is it installable through the marketplace, due to licensing 
issues.

It can, however be installed manually,