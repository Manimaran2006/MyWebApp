
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'manimaran46/mywebapp'
        ANSIBLE_SERVER = '172.31.22.118'
        ANSIBLE_KEY = '/var/lib/jenkins/.ssh/ansible_key'
        NEXUS_URL = 'http://3.90.248.73:8081'
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
                    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                    export PATH=$JAVA_HOME/bin:$PATH

                    java -version
                    javac -version

                    chmod +x mvnw
                    ./mvnw clean package -DskipTests
                '''
            }
        }

        stage('Verify WAR') {
            steps {
                sh '''
                    test -f target/MyWebApp-0.0.5.war
                    echo "WAR file created successfully!"
                    ls -lh target/MyWebApp-0.0.5.war
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                        export PATH=$JAVA_HOME/bin:$PATH

                        chmod +x mvnw

                        ./mvnw sonar:sonar \
                            -Dsonar.projectKey=MyWebApp \
                            -Dsonar.projectName=MyWebApp
                    '''
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh '''
                        set +x

                        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                        export PATH=$JAVA_HOME/bin:$PATH

                        cat > nexus-settings.xml <<EOF
<settings>
    <servers>
        <server>
            <id>nexus-releases</id>
            <username>${NEXUS_USER}</username>
            <password>${NEXUS_PASS}</password>
        </server>
    </servers>
</settings>
EOF

                        chmod 600 nexus-settings.xml

                        ./mvnw -B \
                            -s nexus-settings.xml \
                            -DskipTests \
                            deploy

                        rm -f nexus-settings.xml
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t $DOCKER_IMAGE:latest .
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'trivy-ssh-key',
                        keyFileVariable: 'TRIVY_KEY',
                        usernameVariable: 'TRIVY_USER'
                    )
                ]) {
                    sh '''
                        set -e

                        docker save -o mywebapp.tar $DOCKER_IMAGE:latest

                        ssh -i "$TRIVY_KEY" \
                            -o StrictHostKeyChecking=accept-new \
                            $TRIVY_USER@172.31.28.164 \
                            "mkdir -p ~/trivy-scan"

                        scp -i "$TRIVY_KEY" \
                            -o StrictHostKeyChecking=accept-new \
                            mywebapp.tar \
                            $TRIVY_USER@172.31.28.164:~/trivy-scan/

                        ssh -i "$TRIVY_KEY" \
                            -o StrictHostKeyChecking=accept-new \
                            $TRIVY_USER@172.31.28.164 \
                            "trivy image --input ~/trivy-scan/mywebapp.tar --severity HIGH,CRITICAL --exit-code 1"

                        rm -f mywebapp.tar
                    '''
                }
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

        stage('Deploy using Ansible') {
            steps {
                sh '''
                    set -e

                    echo "Connecting to Ansible EC2..."

                    ssh -i "$ANSIBLE_KEY" \
                        -o BatchMode=yes \
                        -o StrictHostKeyChecking=yes \
                        ubuntu@$ANSIBLE_SERVER \
                        'cd ~/MyWebApp &&
                         git pull origin main &&
                         ansible-playbook \
                         -i ~/ansible-project/inventory.ini \
                         ansible/deploy.yml'
                '''
            }
        }

        
        stage('Verify Deployment') {
            steps {
                sh '''
                    set -e
        
                    echo "Waiting for application startup..."
        
                    for i in $(seq 1 30); do
                        if curl -fsS http://3.80.130.218:8080/ > /dev/null; then
                            echo "SUCCESS: Application is responding!"
                            exit 0
                        fi
        
                        echo "Attempt $i: Application not ready yet..."
                        sleep 5
                    done
        
                    echo "ERROR: Application health check failed!"
                    exit 1
                '''
            }
        }


    post {
        success {
            echo 'SUCCESS: MyWebApp built, scanned, published and deployed using Ansible!'
        }

        failure {
            echo 'FAILED: Check Jenkins Console Output.'
        }

        always {
            sh 'rm -f nexus-settings.xml mywebapp.tar'
            echo 'Jenkins CI/CD Pipeline execution completed.'
        }
    }
}
