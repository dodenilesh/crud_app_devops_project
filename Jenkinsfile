pipeline {
   
     agent { label 'master' }
    
    environment{
        	dockerhub_credentials=credentials('DOCKERHUB_CREDS')
		github_credentials=credentials('GITHUB_CREDS')
		k8s_credentials=credentials('K8S_MASTER_CREDS')			
    }
	

    stages {  
	stage("Git Clone"){
	    steps {
		git credentialsId: github_credentials, url: 'https://github.com/dodenilesh/crud_app_devops_project.git'
		}
            }	
        stage('Build & Package spring app') {
            steps {
                dir('springboot-backend') {
                  sh 'mvn clean '
                  sh 'mvn install -DskipTests '
                }
            }
        }

        stage('Build images of both app') {
            steps {
                dir('springboot-backend') {
		  sh 'whoami'
                  sh 'docker build -t springboot-backend:$BUILD_NUMBER . '
                }
                
                dir('react-frontend') {
                  sh 'docker build -t react-frontend:$BUILD_NUMBER . '
                }
                
            }
        }

        stage('Push images to hub') {
            steps {
                sh 'echo $dockerhub_credentials_PSW | docker login -u $dockerhub_credentials_USR --password-stdin '
                sh 'docker image tag springboot-backend:$BUILD_NUMBER dodenilesh/springboot-backend:$BUILD_NUMBER'
                sh 'docker image push dodenilesh/springboot-backend:$BUILD_NUMBER'
                
                sh 'docker image tag react-frontend:$BUILD_NUMBER dodenilesh/react-frontend:$BUILD_NUMBER'
                sh 'docker image push dodenilesh/react-frontend:$BUILD_NUMBER'
            }
        }

        stage('deploy on kubernetes') {
            steps {
                dir('kubernetes'){
                    sh ''' final_tag=$(echo $BUILD_NUMBER | tr -d ' ') 
                     sed -i "s/docker_tag/$final_tag/g" backend.yml
                    '''

                    sh ''' final_tag=$(echo $BUILD_NUMBER | tr -d ' ') 
                     sed -i "s/docker_tag/$final_tag/g" frontend.yml
                    '''
                }
                dir('ansible_k8s') {                  
                  ansiblePlaybook become: true, credentialsId: 'k8s_credentials', installation: 'ansible', inventory: 'hosts', playbook: 'deploy-playbook.yml'
                }
            }
        }

        stage('Clean up') {
            steps {
                sh 'docker rmi dodenilesh/springboot-backend:$BUILD_NUMBER --force'
                sh 'docker rmi springboot-backend:$BUILD_NUMBER --force'
                
                sh 'docker rmi dodenilesh/react-frontend:$BUILD_NUMBER --force'
                sh 'docker rmi react-frontend:$BUILD_NUMBER --force'
            }
        }
    }
}
