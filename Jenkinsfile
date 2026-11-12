
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'manimaran46/mywebapp'
        DOCKER_SERVER = '34.203.223.233'
        CONTAINER_NAME = 'mywebapp'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    chmod +x mvnw
                    ./mvnw clean package -DskipTests
                '''
            }
        }

        stage('Verify WAR') {
            steps {
                sh '''
                    test -f target/MyWebApp-0.0.1.war
                    ls -lh target/*.war
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t $DOCKER_IMAGE:latest .
                '''
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$DOCKER_PASS" | docker login \
                            -u "$DOCKER_USER" --password-stdin

                        docker push $DOCKER_IMAGE:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Docker EC2') {
            steps {
                sshagent(credentials: ['docker-server-ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=accept-new \
                            ubuntu@$DOCKER_SERVER "
                                docker pull $DOCKER_IMAGE:latest &&
                                (docker rm -f $CONTAINER_NAME || true) &&
                                docker run -d \
                                    --name $CONTAINER_NAME \
                                    --restart unless-stopped \
                                    -p 8081:8080 \
                                    $DOCKER_IMAGE:latest
                            "
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    sleep 10
                    ssh ubuntu@$DOCKER_SERVER \
                        "curl -f http://localhost:8081/"
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: MyWebApp deployed using Docker!'
        }

        failure {
            echo 'FAILED: Check Jenkins Console Output.'
        }
    }
}
