
pipeline {
    agent any

    environment {
        TOMCAT_URL = 'http://172.31.27.60:8080'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Verify WAR') {
            steps {
                sh 'test -f target/MyWebApp.war'
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
                            --upload-file target/MyWebApp.war \
                            "$TOMCAT_URL/manager/text/deploy?path=/&update=true"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    sleep 5
                    curl --fail --show-error \
                        "$TOMCAT_URL/"
                '''
            }
        }
    }
}
