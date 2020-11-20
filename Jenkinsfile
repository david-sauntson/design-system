deployBranches = ['master']
isRelease = deployBranches.contains(env.BRANCH_NAME)

configurationTypes = [
  ['Windows_10_85', 'chrome'],
  ['Windows_10_81', 'firefox'],
  ['Windows_7_80', 'chrome'],
  ['Windows_7_78', 'firefox'],
  ['OSX_Mojave_84', 'chrome'],
  ['OSX_Mojave_12', 'safari'],
  ['iPhone11_13', 'ios'],
  ['iPhone8_12', 'ios'],
]

cron_schedule = isRelease ? '0 2 * * *' : ''

docker_registry = '979633842206.dkr.ecr.eu-west-1.amazonaws.com'
docker_registry_url = "https://${docker_registry}"
ecr_credential = 'ecr:eu-west-1:cita-devops'

images = [:]

global_environment_variables = []

// Pipeline definition begins here

node('docker && awsaccess') {
  try {
    step([
      $class: 'WsCleanup',
      notFailBuild: true
    ])
    checkout scm

    global_environment_variables = [
      "DOCKER_TAG=${env.BRANCH_NAME}_${getSha()}",
      // Using the commit SHA would mean that every build
      // gets a different tag and this busts the cache between PR builds.
      "CA_STYLEGUIDE_VERSION_TAG=${env.BRANCH_NAME}"
    ]

    withEnv(global_environment_variables) {
      currentBuild.displayName = "$BUILD_NUMBER: $DOCKER_TAG"
      slackNotifyReleaseOnly() {
        pipeline()
      }
    }
  }
  finally {
    step([
      $class: 'WsCleanup',
      notFailBuild: true
    ])
  }
}

properties([
  parameters([
    string(defaultValue: '#new_platform_builds', description: 'channel to print messages', name: 'slackChannel'),
    string(defaultValue: 'slack-plugin', description: 'id of slack credentials used when posting a message', name: 'slackCredentialsId')
  ]),
  pipelineTriggers([cron(cron_schedule)])
])

def pipeline() {
  stage('Update Docker Images') {
    docker.withRegistry(docker_registry_url, ecr_credential) {
      // Pull the master images and any previous builds if we're on a different branch
      // docker-compose only looks in the local images and doesn't try to pull when building
      ['ca-styleguide', 'wcag', 'ruby'].each {
        images[it] = "${docker_registry}/design-system:dev_${it}_${env.CA_STYLEGUIDE_VERSION_TAG}"
        // Ignore failures from docker - it's probably an Image Not Found.
        // Other errors like out of disk space will cause problems in other commands
        try {
          docker.image("${docker_registry}/design-system:${it}").pull()
          if (env.BRANCH_NAME != 'master') {
            docker.image(images[it]).pull()
          }
        } catch (Exception e) {
          echo "Error pulling ${images[it]}"
        }
      }

      sh 'docker-compose build'

      // Push updated containers so they can be used on the next run
      ['ca-styleguide', 'wcag', 'ruby'].each {
        if (env.BRANCH_NAME == 'master') {
          // If we're building on master, update the master images.
          // The tag function only changes the last part of the image name (unlike docker tag)
          docker.image("${images[it]}").tag("${it}")
          docker.image("${docker_registry}/design-system:${it}").push()
        } else {
          docker.image("${images[it]}").push()
        }
      }
    }
  }

  stage('Lint') {
    withDockerSandbox([ images['ca-styleguide'], images['ruby'] ]) {
      withEnv(['PRODUCTION=true', 'NODE_ENV=test']) {
        sh 'docker-compose run ruby-tests bundle exec rake ruby:lint'
        sh 'docker-compose run ca-styleguide bundle exec rake npm:lint'
      }
    }
  }

  stage('Unit test') {
    withDockerSandbox([ images['ca-styleguide'] ]) {
      withEnv(['PRODUCTION=true', 'NODE_ENV=test']) {
        sh 'docker-compose run ca-styleguide bundle exec rake npm:jest'
      }
    }

    step ([$class: 'JUnitResultArchiver', testResults: 'testing/visual-regression/backstop_data/ci_report/?*.xml', allowEmptyResults: true])
  }

  stage('Visual Regression Tests') {
    withDockerSandbox(['backstopjs/backstopjs']) {
      try {
        sh './bin/jenkins/visual_regression'
      } catch (Exception e) {
        sh 'docker-compose logs --no-color'
        currentBuild.result = 'FAILURE'
        throw e
      } finally {
        sh './bin/jenkins/fix_visual_test_report'
        publishHTML([
            allowMissing: true,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'reports/html_report',
            reportFiles: 'index.html',
            reportName: 'BackstopJS Report',
        ])
      }
    }
  }

  stage('Accessibility Tests') {
    withDockerSandbox([images['wcag'] ]) {
      try {
        sh './bin/docker/a11y-test'
      } catch (Exception e) {
        sh 'docker-compose logs --no-color'
        currentBuild.result = 'FAILURE'
        throw e
      }
    }
  }

  stage('Grid Tests') {
    parallel define_grid_tests()
  }

  stage('Regression Tests') {
    parallel define_regression_tests()
  }

} //end pipeline



def slackNotifyReleaseOnly(Closure body) {
  if (!isRelease) {
    body()
    return
  }
  withSlackNotifier(
    [
      channel: params.slackChannel,
      credentialsId: params.slackCredentialsId,
      message: "${sh(returnStdout: true, script: 'git log -1')}" +
                "\nBackstop: ${BUILD_URL}BackstopJS_20Report/",
    ]
  ) {
    body()
  }
}

// Grid and Regression Testing

def withTestingNode(String description, Boolean useBrowserStack, Closure body) {
  node('docker && awsaccess') {
    try {
      stage(description) {
        checkout scm
        withEnv(global_environment_variables) {
          if (useBrowserStack) {
            withDockerSandbox([images['ruby']]) {
                withVaultSecrets([
                  BROWSERSTACK_USERNAME: '/secret/devops/public-website/develop/env, BROWSERSTACK_USERNAME',
                  BROWSERSTACK_ACCESS_KEY: '/secret/devops/public-website/develop/env, BROWSERSTACK_ACCESS_KEY',
                ])
                {
                  // Call closure
                  body()
                } // withVaultSecrets
              }
          } else {
            withDockerSandbox(
              [
                images['ruby'],
                'selenium/hub:4.0.0-alpha-6-20200609',
                'selenium/node-chrome:4.0.0-alpha-6-20200609',
                'selenium/node-firefox:4.0.0-alpha-6-20200609'
              ]) {
              // Call closure
              body()
            }
          } // end if
        } // end withEnv
      } // end stage
    } finally {
      step([
        $class: 'WsCleanup',
        notFailBuild: true
      ])
    } // end try/finally
  } // end node
} // end withTestingNode

def define_grid_tests() {
  grid_tests = [:]
  grid_tests.failFast = false

  ['chrome', 'firefox'].each { browser ->
    grid_tests[browser] = {
      withTestingNode("Interim Stage: Test ${browser}", false) {
        try {
          sh "BROWSER=${browser} bin/docker/grid_tests"
          archiveArtifacts(
            [ // The ?* is to get around an annoying warning from the syntax highlighter which doesn't realise that /* in a string isn't the start comment token.
              artifacts: 'testing/${browser}/grid/screenshots/?*.png, ' +
                         'testing/${browser}/grid/reports/report.html, ' +
                         'testing/${browser}/grid/reports/?*.xml, ' +
                         'testing/${browser}/grid/reports/report.json, ' +
                         'testing/${browser}/grid/html_pages/?*.html, ' +
                         'testing/${browser}/grid/logs/?*.log',
              allowEmptyArchive: true,
              caseSensitive: false
            ]
          )
        } catch (Exception e) {
          sh 'docker-compose logs --no-color'
          currentBuild.result = 'FAILURE'
          throw e
        }
      } // end withCucumberNode
    } // end browser grid test block
  }

  return grid_tests
}

def define_regression_tests() {
  regression_tests = [:]
  regression_tests.failFast = false

  configurationTypes.each {
    def stepName = "running ${it}"
    regression_tests[stepName] = {
      withTestingNode('Regression Test of ${it}', true) {
        def (config, browser) = it
        sh "BROWSERSTACK_CONFIGURATION_OPTIONS=$config BROWSER=$browser ./bin/docker/browserstack_tests"
        // Archive artifacts from this test run in $browser/$config
        archiveArtifacts(
          [ // The ?* is to get around an annoying warning from the syntax highlighter which doesn't realise that /* in a string isn't the start comment token.
            artifacts: 'testing/${browser}/${config}/screenshots/?*.png, ' +
                       'testing/${browser}/${config}/reports/report.html, ' +
                       'testing/${browser}/${config}/reports/?*.xml, ' +
                       'testing/${browser}/${config}/reports/report.json, ' +
                       'testing/${browser}/${config}/html_pages/?*.html, ' +
                       'testing/${browser}/${config}/logs/?*.log',
            allowEmptyArchive: true,
            caseSensitive: false
          ]
        )
      }
    }
  } // end regression test block
}
