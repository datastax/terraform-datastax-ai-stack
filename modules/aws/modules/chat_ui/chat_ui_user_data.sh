#!/bin/bash

sudo yum update -y
yum install jq -y
echo ${token}
echo "export CLIENT_ID=$CLIENT_ID" >> /home/ec2-user/.bashrc
export MONGODB_URL=${mongodb_url}
echo "export MONGODB_URL=$MONGODB_URL" >> /home/ec2-user/.bashrc
export HF_TOKEN=${hf_token}
echo "export HF_TOKEN=$HF_TOKEN" >> /home/ec2-user/.bashrc
export PUBLIC_ORIGIN=${public_origin}
echo "export PUBLIC_ORIGIN=$PUBLIC_ORIGIN" >> /home/ec2-user/.bashrc
export ENABLE_ASSISTANTS=true
echo "export ENABLE_ASSISTANTS=$ENABLE_ASSISTANTS" >> /home/ec2-user/.bashrc
export USE_LOCAL_WEBSEARCH=true
echo "export USE_LOCAL_WEBSEARCH=$USE_LOCAL_WEBSEARCH" >> /home/ec2-user/.bashrc
export OPENAI_API_KEY=${openai_api_key}
echo "export OPENAI_API_KEY=$OPENAI_API_KEY" >> /home/ec2-user/.bashrc
ASTRA_API_TOKEN=$(token)
export ASTRA_API_TOKEN
echo "export ASTRA_API_TOKEN=$ASTRA_API_TOKEN" >> /home/ec2-user/.bashrc
export PERPLEXITYAI_API_KEY=${perplexityai_api_key}
echo "export PERPLEXITYAI_API_KEY=$PERPLEXITYAI_API_KEY" >> /home/ec2-user/.bashrc
export COHERE_API_KEY=${cohere_api_key}
echo "export COHERE_API_KEY=$COHERE_API_KEY" >> /home/ec2-user/.bashrc
export GEMINI_API_KEY=${gemini_api_key}
echo "export GEMINI_API_KEY=$GEMINI_API_KEY" >> /home/ec2-user/.bashrc
export TASK_MODEL=${task_model}
echo "export TASK_MODEL=$TASK_MODEL" >> /home/ec2-user/.bashrc
export MODELS=${models}
echo "export MODELS=$MODELS" >> /home/ec2-user/.bashrc

su ec2-user -c 'git clone https://@github.com/datastax/chat-ui.git'
su ec2-user -c 'cd chat-ui'
su ec2-user -c 'git switch assistants'
su ec2-user -c 'npm install'
su ec2-user -c 'npm run build'
su ec2-user curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
su ec2-user source ~/.bashrc
su ec2-user nvm install --lts
su ec2-user -c 'npm install pm2 -g'

su ec2-user pm2 start /app/build/index.js -i "$CPU_CORES" --no-daemon
