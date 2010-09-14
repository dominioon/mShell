require File.dirname(__FILE__) + "/../nmibuilder"

$module_data = {
  :author => 'Dominus',
  :name => 'Profiles',
  :description => 'mShell Profiles module',
  :version => '1,0,0',
  :source => 'ProfilesModule.cpp',
  :ext_libs => 'profileengine.lib'       
}

# S60 3rd Edition, FP1
$version_data[:ver3][:product_id] = '[0x102032BE]'

$targets = $all_v3s60 + $all_v5

build
