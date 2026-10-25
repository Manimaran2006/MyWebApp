
pipeline {
    agent any

    environment {
        TOMCAT_URL = 'http://54.198.234.225:8080'
        WAR_FILE = 'target/MyWebApp-0.0.1.war'
        APP_PATH = '/myapp'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'chmod +x mvnw'
                sh './mvnw -B clean package -DskipTests'
            }
        }

        stage('Verify WAR') {
            steps {
                sh 'test -f target/MyWebApp-0.0.1.war'
                sh 'ls -lh target/*.war'
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                withCredentials([
                    usernameColonPassword(
                        credentialsId: 'tomcat-credentials',
                        variable: 'TOMCAT_CREDS'
                    )
                ]) {
                    sh '''
                        set +x
                        curl --fail --show-error \
                          --user "$TOMCAT_CREDS" \
                          --upload-file "$WAR_FILE" \
                          "$TOMCAT_URL/manager/text/deploy?path=$APP_PATH&update=true"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    sleep 5
                    curl --fail --show-error \
                      "$TOMCAT_URL$APP_PATH/"
                '''
            }
        }
    }
}
