require File.dirname(__FILE__) + "/../nmibuilder"

$module_data = {
  :author => 'Dominus',
  :name => 'Dtmf',
  :description => 'mShell DTMF module',
  :version => '1,0,0',
  :source => 'DtmfModule.cpp',
  :ext_libs => 'etel3rdparty.lib'       
}

$targets = $all

build
