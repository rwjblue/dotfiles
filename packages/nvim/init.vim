runtime bundle/pathogen/autoload/pathogen.vim
call pathogen#infect()

source ./basic_setup.vim
source ./file_type_config.vim
source ./plugin_config.vim
source ./statusline.vim
source ./mappings.vim
source ./custom_commands.vim

set t_Co=256
color zenburn

