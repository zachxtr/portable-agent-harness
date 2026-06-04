# Bedrock & AWS (ops note)

Environment notes for local/dev containers and avatar generation.

- Chat LLM: `AWS_REGION=us-east-1`, `BEDROCK_MODEL_ID=us.anthropic.claude-sonnet-4-6`
- Avatar images: `BEDROCK_IMAGE_REGION=us-west-2`, `BEDROCK_IMAGE_MODEL_ID=stability.stable-image-ultra-v1:1`
- us-east-1 image models (Nova Canvas, Titan) are LEGACY — blocked for new/inactive accounts
- us-west-2 has ACTIVE Stability text-to-image models
- Container restart required after env changes (not nodemon hot reload)
