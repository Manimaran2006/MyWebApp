
pipeline {
    agent any

    environment {
        TOMCAT_HOST = '172.31.23.181'
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

        stage('Verify WAR') {
            steps {
                sh '''
                    set -eu
                    ls -lh target/*.war
                    test "$(find target -maxdepth 1 -type f -name '*.war' | wc -l)" -gt 0
                '''
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'tomcat-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        set -eu

                        WAR_FILE=$(find target -maxdepth 1 \
                            -type f -name "*.war" | head -n 1)

                        test -f "$WAR_FILE"

                        echo "Preparing SSH connection..."
                        mkdir -p "$HOME/.ssh"
                        chmod 700 "$HOME/.ssh"

                        ssh-keyscan -H "$TOMCAT_HOST" \
                            >> "$HOME/.ssh/known_hosts"
                        chmod 600 "$HOME/.ssh/known_hosts"

                        echo "Copying WAR to Tomcat server..."
                        scp -i "$SSH_KEY" \
                            -o BatchMode=yes \
                            "$WAR_FILE" \
                            "$SSH_USER@$TOMCAT_HOST:/home/$SSH_USER/MyWebApp.war"

                        echo "Deploying application..."
                        ssh -i "$SSH_KEY" \
                            -o BatchMode=yes \
                            "$SSH_USER@$TOMCAT_HOST" \
                            "sudo install -o tomcat -g tomcat -m 644 \
                             /home/$SSH_USER/MyWebApp.war \
                             /var/lib/tomcat10/webapps/ROOT.war &&
                             sudo systemctl restart tomcat10"

                        echo "Deployment commands completed."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Build and deployment completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check Console Output for the first error.'
        }
    }
}
