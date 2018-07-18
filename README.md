# match_certs_migration


I used match in our project, and match regenerated the certificate when the project was created. The number of developer accounts is limited to three, and in fact the same type of certificate can be reused, then use the match to fetch different provision files. The fastlane action match_certs_migration will reuse the certificates. 

### Usage


In your Fastfile 

```
# git_url -> your certs repo git url
# username -> developer account username
# app_identifier -> app bundle_identifier
# type -> cert type ('development', 'appstore', 'enterprise', 'adhoc', 'distribution')


  desc "exsting certificates migration, match with option `readonly: false` after the lane finished successfully"
  lane :rrc_match_certs_migration do |options|
    match_certs_migration(
      git_url: git_url,
      username: username,
      app_identifier: app_identifier,
      type: type,
    )
  end

```
next you need to execute the match, since there's no provision file in the git repo, you should add  `--readonly false` when you execute the match. Match will fetch provisons for you, so the problem is solved.

As match has stored the cert and p12 files in the git repo, and they are named with the cert_id,

The action will check out all the branches and copy all the certs to a tmp dirctory, fetch all the certificates on the developer account and choose a suitable cert, get the cert and p12 files from the all certs tmp directory and then commit them to your cert git repo. That's it.

### Notice
When I used the action in my project. To make it easy, there were only README.md and match_version.txt in the directory of default branch master,thus all I need to do is copy the certs directory here and commit the changes.

You may have some problems with using it if your directory structure of the default branch is different from mine, you can modify the directory structure as I did, and it would be amazing if you could fix it.

The directory structure of my default branch master is shown below.

![image](https://github.com/HIIgor/match_certs_migration/blob/master/screen_shot.jpeg)


