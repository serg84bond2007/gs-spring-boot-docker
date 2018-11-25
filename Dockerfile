String checkboxDescription = 'Set checkbox to true if you want to run integration tests'
String systemTestCustomer = 'ormat'
String systemTestSite = 'steamboat15'
String systemTestTestSite = 'AT_JENKINS_PIPELINE_test_site'
String systemRunName = '"AT Jenkins Pipeline detector system test"'
String systemTestSuffix = '"'+JOB_NAME.replace("/",".")+"."+BUILD_NUMBER+'"'
String systemTestStartDate = '2015-12-01'
String systemTestEndDate = '2015-12-31'
String systemTestIMDBIP = '10.100.0.232'
String systemTestWorkIP = '10.100.0.35'

properties([parameters([booleanParam(defaultValue: false, description: checkboxDescription, name: 'integrationTestsRun'),
booleanParam(defaultValue: JOB_NAME.contains("anomalies_hadoop/develop"), description: 'Set checkbox to true if you want to run detector system tests', name: 'detectorSystemTestsRun')])])

node {
    try {
        stage('Build') {
                echo 'Building...'
                deleteDir()
                checkout scm
                if (env.BRANCH_NAME.startsWith("PR-") || env.BRANCH_NAME.equals("develop") || params.integrationTestsRun) {
                    docker.image("maven:3.5.2-jdk-8").inside('-v "$HOME/.m2":/var/maven/.m2:rw,z -v /etc/passwd:/etc/passwd:ro -e M2_HOME=/var/maven/.m2') {
                        sh 'mvn  -Duser.home=/var/maven/  --batch-mode clean install'
                        sh "mvn -Duser.home=/var/maven/  sonar:sonar -Dsonar.userHome=/tmp/.sonar/cache -Dsonar.branch=${env.BRANCH_NAME}" +
                        ' -Dsonar.exclusions="src/main/java/moa//*,src/main/java/weka//*,src/main/java/com/yahoo//*"' +
                        ' -Dsonar.host.url=http://10.100.0.215:9000 -Dsonar.login=d6e7e0d6aa96f8a3ac86df7a9fb2dc219084387b'
    }
        if (params.detectorSystemTestsRun){
                  sshagent (credentials: ['a6309e49-e74b-44c4-9975-279800d6b45e']) {
                        sh("git clone git@bitbucket.org:PreSenso/testing_detector.git; cd testing_detector")
       }
                  docker.image("gradle:4.10.1-jdk8").inside('-v /etc/passwd:/etc/passwd:ro') {
                        sh "cd testing_detector;chmod 777 gradlew; ./gradlew -g \$(pwd) clean test -Dcustomer=${systemTestCustomer} -Dsite=${systemTestSite} -DtestSite=${systemTestTestSite} -DstartDate=${systemTestStartDate} -DendDate=${systemTestEndDate} -DworkIP=${systemTestWorkIP} -DimdbIP=${systemTestIMDBIP} -DworkSuffix=${systemTestSuffix} -DworkDir=/home/yauhenihraichonak/JENKINS_PIPELINE/ -DrunName=${systemRunName}"

                  }
             }
                } else {
                    docker.image("maven:3.5.2-jdk-8").inside('-v "$HOME/.m2":/var/maven/.m2:rw,z -v /etc/passwd:/etc/passwd:ro -e M2_HOME=/var/maven/.m2') {
                        sh 'mvn  -Duser.home=/var/maven/  --batch-mode clean package'
                        sh "mvn -Duser.home=/var/maven/  sonar:sonar -Dsonar.userHome=/tmp/.sonar/cache -Dsonar.branch=${env.BRANCH_NAME}" +
                        ' -Dsonar.exclusions="src/main/java/moa//*,src/main/java/weka//*,src/main/java/com/yahoo//*"' +
                        ' -Dsonar.host.url=http://10.100.0.215:9000 -Dsonar.login=d6e7e0d6aa96f8a3ac86df7a9fb2dc219084387b'
                    }
                }
        }
        stage('Test') {
                echo 'Testing...'
             if (params.detectorSystemTestsRun){
                echo 'Test results publishing ...'
                junit([testResults:'testing_detector/build/test-results/**/*.xml',allowEmptyResults: true,healthScaleFactor :0.0])
                publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'testing_detector/reports', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: ''])
                }
        }
        stage('Deploy') {
                echo 'Deploying...'
        }
    } catch (Exception e) {
        println "Something goes wrong: $e"
        String fileName="log_build_" + env.BUILD_NUMBER + ".txt"
        sh "mv log.txt $fileName; gzip $fileName"

Едем Лайф, [25.11.18 17:58]
archiveArtifacts allowEmptyArchive: true, artifacts: "$fileName"+".gz"
        currentBuild.result = 'FAILURE'
    }
}
