# match_certs_migration


I used the match in our project. I find that the fastlane match will creat a new certificate for us if a new project is created, and the limitation of certificate count is 3. Actually there's no problem reusing the certificate of the same type, then using the match to generate different provisions for different bundle_identifier can perfectly solve the problem. and the fastlane action match_certs_migration is what you want.

### Usage


In your Fastfile 

```
# git_url -> your certs repo git url
# username -> developer account username
# app_identifier -> app bundle_identifier
# type -> cert type ('development', 'appstore', 'enterprise', 'adhoc', 'distribution')


match_certs_migration(	
  git_url: git_url,
  username: username,
  app_identifier: app_identifier,
  type: type,
)

```
next you need to execute the match, since there's no provision file in the git repo, you should add  `--readonly false` when you execute the match. Match will fetch provisons for you, so the problem is solved.

As match has stored the cert and p12 files on the git repo, and they are named with the cert_id,

The action will check out all the branches and copy all the certs to a tmp dirctory, fetch all the certificates on the developer account and choose a suitable cert, get the cert and p12 files from the all certs tmp directory and then commit them to your cert git repo. That's it.

