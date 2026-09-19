pipeline {

    agent any

    environment {

        GITHUB_CREDENTIALS = 'gitHub'

        SONAR_TOKEN = credentials('sonarqube-token')
        SONAR_HOST_URL = 'http://98.80.200.139:9000'

        NEXUS_CREDENTIALS = 'nexus-credentials'

        TOMCAT_CREDENTIALS = 'Tomcat-credential'
        TOMCAT_URL = 'http://44.200.26.53:8080'

        APP_NAME = 'MyWebApp'
    }

    stages {

        // ==========================================
        // CHECKOUT
        // ==========================================

        stage('Checkout') {
            steps {
                echo '===== CHECKOUT FROM GITHUB ====='

                checkout scm
            }
        }


        // ==========================================
        // MAVEN BUILD
        // ==========================================

        stage('Maven Build') {
            steps {
                echo '===== MAVEN BUILD ====='

                sh '''
                    mvn \
                    -s /var/lib/jenkins/.m2/empty-settings.xml \
                    clean package \
                    -DskipTests
                '''
            }
        }


        // ==========================================
        // TEST
        // ==========================================

        stage('Test') {
            steps {
                echo '===== RUNNING TESTS ====='

                sh '''
                    mvn \
                    -s /var/lib/jenkins/.m2/empty-settings.xml \
                    test
                '''
            }
        }


        // ==========================================
        // SONARQUBE
        // ==========================================

        stage('SonarQube Analysis') {
            steps {

                echo '===== SONARQUBE ANALYSIS ====='

                sh '''
                    mvn \
                    -s /var/lib/jenkins/.m2/empty-settings.xml \
                    org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                    -Dsonar.projectKey=MyWebApp \
                    -Dsonar.host.url=${SONAR_HOST_URL} \
                    -Dsonar.token=${SONAR_TOKEN}
                '''
            }
        }


        // ==========================================
        // TRIVY SECURITY SCAN
        // ==========================================

        stage('Security Scan') {
            steps {

                echo '===== TRIVY SECURITY SCAN ====='

                sh '''
                    trivy fs \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    .
                '''
            }
        }


        // ==========================================
        // NEXUS DEPLOYMENT
        // ==========================================

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

                cat > /var/lib/jenkins/settings.xml <<EOF
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

                echo "===== CHECKING MAVEN SETTINGS ====="

                cat /var/lib/jenkins/settings.xml

                echo "===== CHECKING WAR ====="

                ls -lh target/*.war

                echo "===== DEPLOYING TO NEXUS ====="

                mvn clean deploy \
                    -DskipTests \
                    -s /var/lib/jenkins/settings.xml

                echo "===== NEXUS DEPLOYMENT COMPLETED ====="
            '''
        }
    }
}


        // ==========================================
        // TOMCAT DEPLOYMENT
        // ==========================================

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

                        WAR_FILE=$(find target \
                            -maxdepth 1 \
                            -type f \
                            -name "*.war" \
                            | head -n 1)

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


        // ==========================================
        // VERIFY DEPLOYMENT
        // ==========================================

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


    // ==========================================
    // POST ACTIONS
    // ==========================================

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
Trivy        : SUCCESS
Nexus        : SUCCESS
Tomcat       : SUCCESS

Application:
http://44.214.44.86:8080/MyWebApp

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