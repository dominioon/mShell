require File.dirname(__FILE__) + "/../nmibuilder"

$module_data = {
  :author => 'Dominus',
  :name => 'UI2',
  :description => 'mShell UI2 module',
  :version => '2,0,0',
  :source => 'Ui2Module2.cpp',
  :ext_libs => 'avkon.lib eikcdlg.lib eikctl.lib'       
}

$targets = $all

build