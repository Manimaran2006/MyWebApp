pipeline {

    agent any

    environment {

        GITHUB_CREDENTIALS = 'gitHub'

        SONAR_TOKEN = credentials('sonarqube-token')
        SONAR_HOST_URL = 'http://18.232.146.38:9000'

        NEXUS_CREDENTIALS = 'nexus-credentials'

        TOMCAT_CREDENTIALS = 'Tomcat-credential'
        TOMCAT_URL = 'http://34.205.85.6:8080'

        APP_NAME = 'MyWebApp'
    }

    stages {

        stage('Checkout') {
            steps {
                echo '===== CHECKOUT FROM GITHUB ====='

                git(
                    url: 'https://github.com/Manimaran2006/MyWebApp.git',
                    branch: 'main',
                    credentialsId: "${GITHUB_CREDENTIALS}"
                )
            }
        }

        stage('Maven Build') {
            steps {
                echo '===== MAVEN BUILD ====='

                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                echo '===== RUNNING TESTS ====='

                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {

            steps {
        
                echo '===== SONARQUBE ANALYSIS ====='
        
                sh '''
                    mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                        -Dsonar.projectKey=MyWebApp \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.token=${SONAR_TOKEN}
                '''
            }
        }

        stage('Deploy to Nexus') {
            steps {
                echo '===== DEPLOYING TO NEXUS ====='

                withCredentials([
                    usernamePassword(
                        credentialsId: "${NEXUS_CREDENTIALS}",
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )
                ]) {

                    sh '''
                        echo "===== CREATING MAVEN SETTINGS ====="

                        mkdir -p ~/.m2

                        cat > ~/.m2/settings.xml <<EOF
                <settings>
                    <servers>
                        <server>
                            <id>nexus-releases</id>
                            <username>${NEXUS_USER}</username>
                            <password>${NEXUS_PASSWORD}</password>
                        </server>
                    </servers>
                </settings>
                EOF

                        echo "===== CHECKING WAR ====="

                        ls -lh target/*.war

                        echo "===== DEPLOYING TO NEXUS ====="

                        mvn deploy \
                            -DskipTests \
                            -s ~/.m2/settings.xml

                        echo "===== NEXUS DEPLOYMENT COMPLETED ====="
                    '''
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo '===== DEPLOYING WAR TO TOMCAT ====='

                withCredentials([
                    usernamePassword(
                        credentialsId: "${TOMCAT_CREDENTIALS}",
                        usernameVariable: 'TOMCAT_USER',
                        passwordVariable: 'TOMCAT_PASSWORD'
                    )
                ]) {

                    sh '''
                        echo "===== SEARCHING FOR WAR ====="

                        WAR_FILE=$(find target -maxdepth 1 -type f -name "*.war" | head -n 1)

                        if [ -z "$WAR_FILE" ]; then
                            echo "ERROR: WAR FILE NOT FOUND"
                            ls -la target/
                            exit 1
                        fi

                        echo "WAR FILE FOUND:"
                        echo "$WAR_FILE"

                        echo "===== DEPLOYING TO TOMCAT ====="

                        curl --fail \
                            --upload-file "$WAR_FILE" \
                            --user "$TOMCAT_USER:$TOMCAT_PASSWORD" \
                            "$TOMCAT_URL/manager/text/deploy?path=/${APP_NAME}&update=true"

                        echo "===== TOMCAT DEPLOYMENT COMPLETED ====="
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '===== VERIFYING TOMCAT APPLICATION ====='

                sh '''
                    sleep 10

                    curl --fail \
                        "$TOMCAT_URL/${APP_NAME}/"

                    echo ""
                    echo "=========================================="
                    echo "APPLICATION DEPLOYED SUCCESSFULLY"
                    echo "=========================================="
                '''
            }
        }
    }

    post {

        success {
            echo '''
==========================================
          PIPELINE SUCCESS
==========================================

GitHub       : SUCCESS
Maven Build  : SUCCESS
Tests        : SUCCESS
SonarQube    : SUCCESS
Nexus        : SUCCESS
Tomcat       : SUCCESS

Application:
http://3.238.44.12:8080/MyWebApp

==========================================
'''
        }

        failure {
            echo '''
==========================================
          PIPELINE FAILED
==========================================

Check the FIRST ERROR in Console Output.

==========================================
'''
        }

        always {
            echo '===== PIPELINE COMPLETED ====='
        }
    }
}