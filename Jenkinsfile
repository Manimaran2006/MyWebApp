
pipeline {
    agent any

    environment {
        TOMCAT_HOST = '52.90.149.225'
        TOMCAT_PORT = '8080'
        APP_NAME    = 'ROOT'
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

        stage('Verify WAR File') {
            steps {
                sh '''
                    set -eu

                    WAR_FILE=$(find target -maxdepth 1 -type f -name "*.war" | head -n 1)

                    if [ -z "$WAR_FILE" ]; then
                        echo "ERROR: WAR file not found in target directory."
                        exit 1
                    fi

                    echo "WAR file found:"
                    ls -lh "$WAR_FILE"
                '''
            }
        }

        stage('Test') {
            steps {
                sh 'mvn -B test'
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'tomcat-credentials',
                        usernameVariable: 'TOMCAT_USER',
                        passwordVariable: 'TOMCAT_PASS'
                    )
                ]) {
                    sh '''
                        set -eu

                        WAR_FILE=$(find target -maxdepth 1 -type f -name "*.war" | head -n 1)

                        if [ -z "$WAR_FILE" ]; then
                            echo "ERROR: No WAR file available for deployment."
                            exit 1
                        fi

                        echo "Deploying application to Tomcat..."

                        curl --fail --show-error \
                            --connect-timeout 10 \
                            --max-time 180 \
                            --user "$TOMCAT_USER:$TOMCAT_PASS" \
                            --upload-file "$WAR_FILE" \
                            "http://${TOMCAT_HOST}:${TOMCAT_PORT}/manager/text/deploy?path=/${APP_NAME}&update=true"

                        echo "Deployment request completed."
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -eu

                    echo "Checking deployed application..."

                    curl --fail --show-error \
                        --connect-timeout 10 \
                        --max-time 30 \
                        "http://${TOMCAT_HOST}:${TOMCAT_PORT}/"
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Build, tests, and Tomcat deployment completed!'
            echo 'Application URL: http://52.90.149.225:8080/'
        }

        failure {
            echo 'FAILURE: Check the Jenkins Console Output for the exact error.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
