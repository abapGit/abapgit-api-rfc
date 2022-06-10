# abapGit API
This API enables you to perform essential abapGit functions on a remote SAP system. 

## Overview
abapGit API can be used for building your CI tools and integrations. 

It allows you to perform the following actions:
1. Link the repository
2. Pull the repository
3. Switch the branch
4. Unlink the repository

## Requirements and installation
1. Install the [sapcli](https://github.com/jfilak/sapcli)
2. Install PyRFC
3. Add a configuration file (as documented in the sapcli repository)
4. The remote SAP system must have [abapGit developer version](https://github.com/abapGit/abapGit) and abapgit-api-rfc (this repo) installed 

##  Usage
### Create link
ZABAPGIT_API_RFC_LINK
- required
    - GIT_REPO_URL
    - GIT_USER
    - GIT_PASSWORD
- optional
    - ABAP_PACKAGE
    - BRANCH
    - FOLDER_LOGIC
    - IGNORE_SUBPACKAGES
    - MAIN_LANG_ONLY
    - STARTING_FOLDER 

example:
```
sapcli startrfc -c bapi ZABAPGIT_API_RFC_LINK -S=GIT_REPO_URL:https://github.com/abapGit/background_modes -S=GIT_USER:filak-sap -S=GIT_PASSWORD:${MY_GH_TOKEN} -S=ABAP_PACKAGE:'$BACKGROUND_MODES'
```

### Pull Repo
ZABAPGIT_API_RFC_PULL
- required
    - ABAP_PACKAGE
    - GIT_USER
    - GIT_PASSWORD
- optional
    - CORRNR

example:
```
sapcli startrfc -c bapi ZABAPGIT_API_RFC_PULL -S=ABAP_PACKAGE:'$BACKGROUND_MODES' -S=GIT_USER:filak-sap -S=GIT_PASSWORD:${MY_GH_TOKEN}
```

### Switch branch
ZABAPGIT_API_RFC_SWITCHBRANCH
- required
    - ABAP_PACKAGE
    - GIT_USER
    - GIT_PASSWORD
- optional
    - BRANCH_NAME

example:
```
sapcli startrfc -c bapi ZABAPGIT_API_RFC_SWITCHBRANCH -S=ABAP_PACKAGE:'$BACKGROUND_MODES' -S=GIT_USER:filak-sap -S=GIT_PASSWORD:${MY_GH_TOKEN} -S=BRANCH_NAME:main
```

### Unlink
ZABAPGIT_API_RFC_UNLINK
- required
    - ABAP_PACKAGE

example:
```
sapcli startrfc -c bapi ZABAPGIT_API_RFC_UNLINK -S=ABAP_PACKAGE:'$BACKGROUND_MODES'
```

