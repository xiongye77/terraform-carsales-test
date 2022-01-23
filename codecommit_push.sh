AWS_CODECMIT_COMMIT_ID1=$(aws codecommit put-file    --repository-name demo    --branch-name main     --file-content file://./buildspec.yml --file-path  buildspec.yml --name 'ye' --email 'ye.xiong@carsales.com.au'  --cli-binary-format raw-in-base64-out  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID1
AWS_CODECMIT_COMMIT_ID2=$(aws codecommit put-file    --repository-name demo     --branch-name main     --file-content file://./appspec.yaml --file-path  appspec.yaml --name 'ye' --email 'ye.xiong@carsales.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID1"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID2
AWS_CODECMIT_COMMIT_ID3=$(aws codecommit put-file    --repository-name demo     --branch-name main     --file-content file://./create-new-task-def.sh --file-path  create-new-task-def.sh --name 'ye' --email 'ye.xiong@carsales.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID2"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID3
AWS_CODECMIT_COMMIT_ID4=$(aws codecommit put-file    --repository-name demo    --branch-name main     --file-content file://./package.json --file-path  package.json --name 'ye' --email 'ye.xiong@carsales.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID3"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID4
AWS_CODECMIT_COMMIT_ID5=$(aws codecommit put-file    --repository-name demo     --branch-name main     --file-content file://./server.js --file-path  server.js --name 'ye' --email 'ye.xiong@carsales.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID4"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID5
AWS_CODECMIT_COMMIT_ID6=$(aws codecommit put-file    --repository-name demo    --branch-name main     --file-content file://./Dockerfile --file-path  Dockerfile --name 'ye' --email 'ye.xiong@carsales.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID5"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID6
