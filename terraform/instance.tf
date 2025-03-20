# Create a new Lightsail Key Pair
resource "aws_lightsail_key_pair" "key-pair" {
  name = "${var.app}-key-pair"
}

# Lightsail Instance
resource "aws_lightsail_instance" "instance" {
  name                  = "${var.app}-instance"
    availability_zone   = "us-east-1a"
    blueprint_id        = "ubuntu_24_04"
    bundle_id           = "medium_3_0" 
    key_pair_name       = aws_lightsail_key_pair.key-pair.name
    user_data = <<-EOF
        #!/bin/bash
        apt-get update -y

        # Set up the environment variables
        export HOME="/home/ubuntu"
        export BRANCH_NAME="${var.branch}"
        export GH_PAT="${var.ghpat}"
        export ENV="${var.env}"
        export APP="openai_nicegui_chat"
        export LANGCHAIN_API_KEY="${var.langchain_api_key}"
        export OPENAI_API_KEY="${var.openai_api_key}"
        
        # Install UV
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source $HOME/.local/bin/env

        # Clone the GitHub repository
        cd $HOME
        mkdir -p $APP
        cd $APP
        git clone https://github.com/stevethomas15977/openai_nicegui_chat.git .
        git checkout $BRANCH_NAME
        
        sh -c "cat > $HOME/$APP/.env" <<EOG
        HOME="$HOME"
        VERSION="0.3.0"
        ENV="$ENV"
        APP="$APP"
        LANGCHAIN_API_KEY="$LANGCHAIN_API_KEY"
        LANGCHAIN_TRACING_V2="true"
        OPENAI_API_KEY="$OPENAI_API_KEY"
        EOG

        # Create a python virtual environment
        python_version=$(python3 --version | awk '{print $2}')
        $HOME/.local/bin/uv venv --python $python_version
        $HOME/.local/bin/uv sync  
        
        # Adjust permissions
        chown -R ubuntu:ubuntu $HOME

        # Create the service file and start the service
        sudo sh -c "cat > /etc/systemd/system/openai_nicegui_chat.service" <<EOT
        [Unit]
        Description=afe daemon
        After=network.target

        [Service]
        User=ubuntu
        Group=ubuntu
        WorkingDirectory=/home/ubuntu/openai_nicegui_chat
        ExecStart=/bin/bash /home/ubuntu/openai_nicegui_chat/start_api.sh

        [Install]
        WantedBy=multi-user.target
        EOT

        sudo setcap 'cap_net_bind_service=+ep' /usr/bin/python3.12

        sudo systemctl daemon-reload
        sudo systemctl start openai_nicegui_chat
        sudo systemctl enable openai_nicegui_chat
        sudo systemctl status openai_nicegui_chat --no-pager

        touch /var/log/user_data_complete
        chmod 644 /var/log/user_data_complete
    EOF
}

resource "aws_lightsail_instance_public_ports" "public_ports" {
    instance_name = aws_lightsail_instance.instance.name

    port_info {
       from_port = 22
       to_port = 22
       protocol = "tcp"
     }

    port_info {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
    }
}