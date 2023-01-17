from api4jenkins import Jenkins

jenkins_client = Jenkins('http://3.231.107.29:8080', auth=('admin', 'password'))

##UserId/Pswd creation
xmlPayload = '''<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <id>test</id>
  <username>test_user</username>
  <password>upassword</password>
  <description>user id for testing</description>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>'''

#jenkins_client.credentials.create(xmlPayload)

# ##SSH keys creation
# with open("/home/oem/.ssh/id_rsa","r") as file:
#     ssh_key = file.read().rstrip()
# sshPayload = f'''<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@1.16">
#   <scope>GLOBAL</scope>
#   <id>Kubernetes_Master</id>
#   <description>SSH Credential for K8S Master</description>
#   <username>ubuntu</username>
#   <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
#     <privateKey>ssh_key</privateKey>
#   </privateKeySource>
# </com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>'''


# jenkins_client.credentials.create(sshPayload)
# print(sshPayload)
