pipeline {
    agent any
    
    environment {
        PATH = "/var/jenkins_home/bin:$PATH"   
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout scm
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withAWS(credentials: 'terraform-aws-credentials') {
                    script {
                        sh '''
                            terraform init -input=false
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withAWS(credentials: 'terraform-aws-credentials') {
                    script {
                        sh '''
                            terraform validate
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withAWS(credentials: 'terraform-aws-credentials') {
                    script {
                        sh '''
                            terraform plan -out=tfplan -input=false
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                branch 'main'  
            }
            steps {
                withAWS(credentials: 'terraform-aws-credentials') {
                    script {
                        
                        sh '''
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()  
        }
        success {
            echo 'Terraform workflow completed successfully!'
        }
        failure {
            echo 'Terraform workflow failed. Please check the logs.'
        }
    }
}
