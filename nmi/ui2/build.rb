require File.dirname(__FILE__) + "/../nmibuilder"

$module_data = {
  :author => 'Dominus',
  :name => 'UI2',
  :description => 'mShell UI2 module',
  :version => '3,0,0',
  :source => 'Ui2Module.cpp',
  :ext_libs => 'avkon.lib eikcdlg.lib eikctl.lib'       
}

$targets = $all

build
