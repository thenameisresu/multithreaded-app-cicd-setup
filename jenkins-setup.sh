#!/bin/bash

set -e

echo "=== Jenkins Setup for Multi-threaded App ==="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}===> $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Get Jenkins initial password
print_step "Getting Jenkins initial admin password..."
if [ -f ~/.jenkins/secrets/initialAdminPassword ]; then
    JENKINS_PASSWORD=$(cat ~/.jenkins/secrets/initialAdminPassword)
    echo "Initial Admin Password: $JENKINS_PASSWORD"
    echo "Save this password for first-time login!"
else
    print_warning "Initial password file not found. Jenkins might already be configured."
fi

# Wait for Jenkins to start
print_step "Waiting for Jenkins to be ready..."
until curl -s http://localhost:8080 > /dev/null; do
    echo "Waiting for Jenkins..."
    sleep 5
done
print_success "Jenkins is running!"

# Install Jenkins CLI
print_step "Setting up Jenkins CLI..."
curl -sL http://localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar

echo ""
echo "=== Jenkins Configuration Steps ==="
echo ""
echo "1. Open Jenkins in browser:"
echo "   http://localhost:8080"
echo ""
echo "2. Login with initial password (shown above)"
echo ""
echo "3. Install suggested plugins, plus these additional ones:"
echo "   - Go Plugin"
echo "   - Docker Pipeline"
echo "   - Kubernetes Plugin"
echo "   - Pipeline: Stage View"
echo "   - Blue Ocean"
echo "   - Slack Notification Plugin (optional)"
echo ""
echo "4. Create credentials:"
echo "   a. Docker Hub Credentials:"
echo "      - Kind: Username with password"
echo "      - ID: docker-hub-credentials"
echo "      - Username: your-docker-username"
echo "      - Password: your-docker-token"
echo ""
echo "   b. Kubeconfig:"
echo "      - Kind: Secret file"
echo "      - ID: kubeconfig"
echo "      - File: Upload your ~/.kube/config"
echo ""
echo "5. Configure Go Tool:"
echo "   - Manage Jenkins → Global Tool Configuration"
echo "   - Go → Add Go"
echo "   - Name: go-1.21"
echo "   - Install automatically from golang.org"
echo ""
echo "6. Create Pipeline Job:"
echo "   - New Item → Pipeline"
echo "   - Name: multithread-app-pipeline"
echo "   - Pipeline → Definition: Pipeline script from SCM"
echo "   - SCM: Git"
echo "   - Repository URL: your-git-repo"
echo "   - Script Path: Jenkinsfile"
echo ""

# Create Jenkins job configuration
print_step "Creating sample Jenkins job XML..."
cat > jenkins-job.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Multi-threaded Go Application CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.7.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>YOUR_GIT_REPO_URL</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <n>*/main</n>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

print_success "Jenkins job configuration created: jenkins-job.xml"

echo ""
echo "=== Quick Commands ==="
echo ""
echo "View Jenkins logs:"
echo "  tail -f /usr/local/var/log/jenkins/jenkins.log"
echo ""
echo "Restart Jenkins:"
echo "  brew services restart jenkins-lts"
echo ""
echo "Stop Jenkins:"
echo "  brew services stop jenkins-lts"
echo ""

print_success "Jenkins setup guide complete!"