
pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Manimaran2006/MyWebApp.git'
            }
        }

        stage('Build Trigger Test') {
            steps {
                echo 'GitHub update detected!'
                echo 'Jenkins pipeline is running automatically.'
            }
        }
    }
}
