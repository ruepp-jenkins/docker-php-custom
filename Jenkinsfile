properties(
    [
        githubProjectProperty(
            displayName: 'docker-php-custom',
            projectUrlStr: 'https://github.com/MyUncleSam/docker-php-custom/'
        ),
        disableConcurrentBuilds(abortPrevious: true)
    ]
)

pipeline {
    agent {
        label 'docker'
    }

    environment {
        IMAGE_FULLNAME = 'ruepp/php-custom'
        // comma separated; set to 'linux/amd64,linux/arm64' to also build arm64
        BUILD_PLATFORMS = 'linux/amd64'
        DOCKER_API_PASSWORD = credentials('DOCKER_API_PASSWORD')
    }

    triggers {
        URLTrigger(
            cronTabSpec: 'H/30 * * * *',
            labelRestriction: 'urltrigger',
            entries: [
                // one entry per enabled PHP version - keep in sync with php_versions.conf
                URLTriggerEntry(
                    url: 'https://hub.docker.com/v2/namespaces/library/repositories/php/tags/8.2-apache',
                    contentTypes: [
                        JsonContent(
                            [
                                JsonContentEntry(jsonPath: '$.last_updated')
                            ]
                        )
                    ]
                ),
                URLTriggerEntry(
                    url: 'https://hub.docker.com/v2/namespaces/library/repositories/php/tags/8.3-apache',
                    contentTypes: [
                        JsonContent(
                            [
                                JsonContentEntry(jsonPath: '$.last_updated')
                            ]
                        )
                    ]
                ),
                URLTriggerEntry(
                    url: 'https://hub.docker.com/v2/namespaces/library/repositories/php/tags/8.4-apache',
                    contentTypes: [
                        JsonContent(
                            [
                                JsonContentEntry(jsonPath: '$.last_updated')
                            ]
                        )
                    ]
                ),
                URLTriggerEntry(
                    url: 'https://hub.docker.com/v2/namespaces/library/repositories/php/tags/8.5-apache',
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

    post {
        always {
            discordSend result: currentBuild.currentResult,
                description: env.GIT_URL,
                link: env.BUILD_URL,
                title: JOB_NAME,
                webhookURL: DISCORD_WEBHOOK
        }
    }
}
