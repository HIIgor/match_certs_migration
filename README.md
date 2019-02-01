# match_certs_migration


I used match in our project, and match regenerated the certificate when the project was created. The number of developer accounts is limited to three, and in fact the same type of certificate can be reused, then use the match to fetch different provision files. The fastlane action match_certs_migration will reuse the certificates. 

### Usage

#### Example
 In the example, 
 ```
fastlane hi_match_certs_migration
 ```
 select the app you wish to migration
 
 ```
fastlane hi_match readonly:false keychain_password:your_keychain_password
 ```



### Implementation
As match has stored the cert and p12 files in the git repo, and they are named with the cert_id,
the action will check out all the branches and copy all the certs to a tmp dirctory, fetch all the certificates on the developer account and choose a suitable cert, get the cert and p12 files from the all certs tmp directory and then commit them to your cert git repo. That's it.

### Todo
Check that wether the cert alreadly exists in the git repo before fetch all the certs.
