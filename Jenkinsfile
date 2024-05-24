properties(
    [
        githubProjectProperty(
            displayName: 'docker-php-custom',
            projectUrlStr: 'https://github.com/MyUncleSam/docker-php-custom/'
        )
    ]
)

pipeline {
    agent {
        label 'docker'
    }
    environment {
        IMAGE_FULLNAME = 'ruepp/php-custom'
    }
    triggers {
        URLTrigger(
            cronTabSpec: 'H/30 * * * *',
            entries: [
                URLTriggerEntry(
                    url: 'https://hub.docker.com/v2/namespaces/library/repositories/php/tags/8.2.6-apache',
                    contentTypes: [
                        JsonContent(
                            [
                                JsonContentEntry(jsonPath: '$.last_updated')
                            ]
                        )
                    ]
                )
            ]
        )
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: env.BRANCH_NAME, url: env.GIT_URL
            }
        }
        stage('Build') {
            steps {
                sh 'chmod +x scripts/*.sh'
                sh './scripts/start.sh'
            }
        }
    }
}
