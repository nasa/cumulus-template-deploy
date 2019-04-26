```
├── Jenkinsfile                           Jenkins Pipeline definition files 
├── build
|   | 
|   ├── setup-cumulus.sh                  \
│   ├── deploy-cumulus.sh                  \ Steps in the build pipeline
│   ├── config-dash.sh                     /
│   ├── deploy-dash.sh                    /
|   |   
|   ├── env.sh                            Called by setup-cumulus.sh & deploy-cumulus.sh
|   |    
│   └── deploy-config.sh                  Deploy resources (rules, collections, providers). Requires TIC access.
│    
├── config                                Resources to be deployed by deploy_config.sh 
│   ├── collections
│   │   ├── SIRCGRD.json
│   │   ├── SIRCGRDMETADATA.json
│   │   ├── SIRCSLC.json
│   │   └── SIRCSLCMETADATA.json
│   ├── providers
│   │   └── ASFDAAC.json
│   └── rules
│       ├── MonitorSircQueueOneTime.json
│       └── SircAllInOneOneTime.json
| 
└── create_aws_object.sh.example          Insipration script that builds resources. Could be useful?
```
