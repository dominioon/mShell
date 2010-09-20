require 'ftools'
require 'pathname'

# Predefined constants for different build targets.
$all_v2 = [:S60_2, :UIQ_2]
$all_v3s60 = [:S60_3_SELF, :S60_3_OS, :S60_3_DC]
$all_v3uiq = [:UIQ_3_SELF, :UIQ_3_OS, :UIQ_3_DC]
$all_v3 = $all_v3s60 + $all_v3uiq
$all_v5 = [:S60_5_SELF, :S60_5_OS, :S60_5_DC]
$all = $all_v2 + $all_v3 + $all_v5

# Comment in if you are developing the NMI and want to build it only for one specific target.
# Enabling in_development mode also preserves building files (.mmp, .pkg) and the generated dll.
$in_development = :S60_5_DC

# root folder of your NMI
$nmi_root='C:/S60/nmisdk'

# root folders of your Symbian SDKs
$sdk_data = {
  :ver2 => {
    :dir => 'C:/Symbian/8.1a/S60_2nd_FP3', 
    :device => 'S60_2nd_FP3:com.nokia.series60'
  },
  :ver3 => {
    :dir => 'C:/S60/devices/S60_3rd_FP2_SDK_v1.1',
    :device => 'S60_3rd_FP2_SDK_v1.1:com.nokia.s60'
  },
  :ver5 => {
    :dir => 'C:/S60/devices/S60_5th_Edition_SDK_v1.0',
    :device => 'S60_5th_Edition_SDK_v1.0:com.nokia.s60'
  },
}

#########################################################

$version_data = {
  :ver2 => {
    :m_libs => 'edll.lib euser.lib mRuntime.lib',
    :m_lib_name => 'mRuntime.lib',
    :lib_target_folder => 'epoc32/release/armi/urel/',
    :compiler_name => 'armi',
    :compiled_dll_folder => 'epoc32/release/armi/urel/',
    :dll_target_folder_on_device => '\\system\\apps\\mEnvironment\\',
    :product_id => '(0x101F7960)',
   },
  :ver3 => {
    :m_libs => 'euser.dso mRuntime.dso',
    :m_lib_name => 'mRuntime.dso',
    :lib_target_folder => 'epoc32/release/armv5/lib/',
    :compiler_name => 'gcce',
    :compiled_dll_folder => 'epoc32/release/gcce/urel/',
    :dll_target_folder_on_device => '\\sys\\bin\\',
    :product_id => '[0x101F7961]',
   },
  :ver5 => {
    :m_libs => 'euser.dso mRuntime.dso',
    :m_lib_name => 'mRuntime.dso',
    :lib_target_folder => 'epoc32/release/armv5/lib/',
    :compiler_name => 'gcce',
    :compiled_dll_folder => 'epoc32/release/gcce/urel/',
    :dll_target_folder_on_device => '\\sys\\bin\\',
    :product_id => '[0x1028315F]',
   },
}

$type_data = {
  :ver2 => {
    :m_runtime_uid3 => '0x1020429a',
#    :m_shell_uid3 => '0x10204299',
    :caps => '',
  },
  :self_sign => {
    :m_runtime_uid3 => '0xa0009885',
#    :m_shell_uid3 => '0xa0002f97',
    :caps => 'CAPABILITY LocalServices NetworkServices ReadUserData UserEnvironment WriteUserData',
  },
  :open_sign => {
    :m_runtime_uid3=>'0xe7e0cab8',
#    :m_shell_uid3 => '0xe7e0cab7',
    :caps=>'CAPABILITY LocalServices NetworkServices ReadUserData UserEnvironment WriteUserData Location PowerMgmt ProtServ ReadDeviceData SurroundingsDD SwEvent TrustedUI WriteDeviceData'
  },
  :dev_sign => {
    :m_runtime_uid3=>'0xa0009885',
#    :m_shell_uid3 => '0xa0002f97',
    :caps=>'CAPABILITY LocalServices NetworkServices ReadUserData UserEnvironment WriteUserData Location PowerMgmt ProtServ ReadDeviceData SurroundingsDD SwEvent TrustedUI WriteDeviceData CommDD DiskAdmin MultimediaDD NetworkControl'
  }
}

$mmp_template=
'TARGET %%MODULE_NAME%%_mm.dll
TARGETTYPE dll
UID 0x1000008d %%M_RUNTIME_UID3%%
%%CAPABILITY%%
SOURCEPATH .
SOURCE %%SOURCE%%
USERINCLUDE %%NMI_INCLUDE%%
SYSTEMINCLUDE \epoc32\include
LIBRARY %%M_LIBS%%
LIBRARY %%EXT_LIBS%%
EXPORTUNFROZEN
'

$pkg_template=
'&EN
#{"%%MODULE_DESCRIPTION%%"},(%%M_RUNTIME_UID3%%),%%MODULE_VERSION%%,TYPE=SP
%{"%%AUTHOR%%"}
:"%%AUTHOR%%"
%%PRODUCT_ID%%,0,0,0,{"Series60ProductID"}
"%%SDK_ROOT%%/%%COMPILED_DLL_FOLDER%%%%MODULE_NAME%%_mm.dll"-"!:%%DLL_TARGET_FOLDER%%%%MODULE_NAME%%_mm.dll"
'

#IF package(%%M_SHELL_UID3%%)
#"%%MODULE_NAME%%.mhp"-"!:\private\%%M_SHELL_FOLDER%%\%%MODULE_NAME%%.mhp"
#ENDIF


def system_call command
  success = system command
  if !success and command =~ /\Aabld /
    # on some systems, the batch file cannot be called from Ruby without extension
    success = system(command.gsub(/\Aabld /, 'abld.bat '))
  end
  raise "UNABLE TO CALL '#{command}': #{$?}" unless success
end

def safe_delete file_name
  File.delete file_name if File.exists?(file_name)
end

class Buildall
  def build
    ($in_development ? [$in_development] : $targets).each do |type|
      Kernel.const_get(type).new().build
    end
    cleanup_common_files unless $in_development
  end
  
  def cleanup_common_files
    system_call 'bldmake clean'
    safe_delete 'bld.inf'
  end
end

class Builder
  def build
    if sdk_exists?
      switch_device
      create_inf_file
      create_mmp_file
      create_pkg_file
      copy_m_lib
      bldmake
      abld
      copy_dll_back if $in_development
      package # unless $in_development
      cleanup unless $in_development
    else
      puts "No #{@sdk_version} SDK found, skipping #{self.class}"
    end
  end
  
  def sdk_exists?
    File.exists? $sdk_data[@sdk_version][:dir] 
  end
  
  def switch_device
    system_call "devices -setdefault @#{$sdk_data[@sdk_version][:device]}"
  end

  def create_inf_file
    f = File.new('bld.inf', 'w')
    f.puts 'PRJ_MMPFILES'
    f.puts "#{$module_data[:name]}.mmp"
    f.close
  end
  
  def create_file template, target_file
    out_file = File.new(target_file, 'w')
    template.each_line do |line|
      line.gsub!('%%MODULE_NAME%%', $module_data[:name])
      line.gsub!('%%M_RUNTIME_UID3%%', $type_data[@sign_type][:m_runtime_uid3])
#      line.gsub!('%%M_SHELL_UID3%%', $type_data[@sign_type][:m_shell_uid3])
#      line.gsub!('%%M_SHELL_FOLDER%%', $type_data[@sign_type][:m_shell_uid3].gsub('0x', ''))
      line.gsub!('%%CAPABILITY%%', $type_data[@sign_type][:caps])
      line.gsub!('%%SOURCE%%', $module_data[:source])
      line.gsub!('%%NMI_INCLUDE%%', Pathname.new($nmi_root).relative_path_from(Pathname.new(File.expand_path('.'))).join('include'))
      line.gsub!('%%M_LIBS%%', $version_data[@sdk_version][:m_libs])
      line.gsub!('%%EXT_LIBS%%', $module_data[:ext_libs])
      line.gsub!('%%MODULE_DESCRIPTION%%', $module_data[:description])
      line.gsub!('%%AUTHOR%%', $module_data[:author])
      line.gsub!('%%MODULE_VERSION%%', $module_data[:version])
      line.gsub!('%%SDK_ROOT%%', $sdk_data[@sdk_version][:dir])
      line.gsub!('%%COMPILED_DLL_FOLDER%%', $version_data[@sdk_version][:compiled_dll_folder])
      line.gsub!('%%DLL_TARGET_FOLDER%%', $version_data[@sdk_version][:dll_target_folder_on_device])
      line.gsub!('%%PRODUCT_ID%%', $version_data[@sdk_version][:product_id])
      out_file.write line
    end
    out_file.close
  end

  def bldmake
    system_call 'bldmake bldfiles'
  end

  def copy_m_lib
    from_name = File.join($nmi_root, 'lib', @m_lib_folder, $version_data[@sdk_version][:m_lib_name])
    to_name = File.join($sdk_data[@sdk_version][:dir], $version_data[@sdk_version][:lib_target_folder], $version_data[@sdk_version][:m_lib_name])
    File.copy(from_name, to_name)
  end
  
  def create_mmp_file
    create_file($mmp_template, "#{$module_data[:name]}.mmp")
  end
  
  def create_pkg_file
    create_file($pkg_template, "#{$module_data[:name]}.pkg")
  end
  
  def abld
    system_call "abld build #{$version_data[@sdk_version][:compiler_name]} urel"
  end
  
  def package
    system_call "makesis #{$module_data[:name]}.pkg #{$module_data[:name]}#{@target_sis_sufix}.sis"
  end

  def copy_dll_back
    from_name = File.join($sdk_data[@sdk_version][:dir], $version_data[@sdk_version][:compiled_dll_folder], "#{$module_data[:name]}_mm.dll")
    to_name = File.join('.', "#{$module_data[:name]}_mm#{@target_sis_sufix unless $in_development}.dll")
    File.copy(from_name, to_name)
  end
  
  def cleanup
    system_call "abld clean #{$version_data[@sdk_version][:compiler_name]} urel"
    safe_delete File.join($sdk_data[@sdk_version][:dir], $version_data[@sdk_version][:lib_target_folder], $version_data[@sdk_version][:m_lib_name])
    safe_delete "#{$module_data[:name]}.pkg"
    safe_delete "#{$module_data[:name]}.mmp"
  end
end

class V2Builder < Builder
  def initialize
    super
    @sdk_version = :ver2
    @sign_type = :ver2
  end
  
  def create_pkg_file
    # no packaging in ver2 at the moment, as it seems to require specifying exact M runtime version
  end
  
  def package
    copy_dll_back
  end
end

class V3Builder < Builder  
  def initialize
    super
    @sdk_version = :ver3
  end
end

class SELF < V3Builder
  def initialize
    super
    @sign_type = :self_sign
  end

  def package
    system "createsis create -pass #{rand()} #{$module_data[:name]}.pkg"
    File.rename("#{$module_data[:name]}.SIS", "#{$module_data[:name]}#{@target_sis_sufix}.sis")
  end
  
  def cleanup
    super
    safe_delete 'cert-gen.cer'
    safe_delete 'key-gen.key'
  end
end

class OS < V3Builder
  def initialize
    super
    @sign_type = :open_sign
  end
end

class DC < V3Builder
  def initialize
    super
    @sign_type = :dev_sign
  end
end


class S60_2 < V2Builder
  def initialize
    super
    @target_sis_sufix = '.S60-2rd'
    @m_lib_folder = 'S60'
  end
end

class UIQ_2 < V2Builder
  def initialize
    super
    @target_sis_sufix = '.UIQ2'
    @m_lib_folder = 'UIQ'
  end
end

class S60_3_SELF < SELF
  def initialize
    super
    @target_sis_sufix = '-S60-3rd'
    @m_lib_folder = 'S60_3'
  end
end

class S60_3_OS < OS
  def initialize
    super
    @target_sis_sufix = '-S60-3rd-OS'
    @m_lib_folder = 'S60_3-OS'
  end
end

class S60_3_DC < DC
  def initialize
    super
    @target_sis_sufix = '-S60-3rd-DC'
    @m_lib_folder = 'S60_3'
  end
end

class UIQ_3_SELF < SELF
  def initialize
    super
    @target_sis_sufix = '-UIQ3'
    @m_lib_folder = 'UIQ3'
  end
end

class UIQ_3_OS < OS
  def initialize
    super
    @target_sis_sufix = '-UIQ3-OS'
    @m_lib_folder = 'UIQ3-OS'
  end
end

class UIQ_3_DC < DC
  def initialize
    super
    @target_sis_sufix = '-UIQ3-DC'
    @m_lib_folder = 'UIQ3'
  end
end

module S60_5_mixin
  def as_v5
    @sdk_version = :ver5
    @product_id = '[0x1028315F]'
  end
end

class S60_5_SELF < S60_3_SELF
  include S60_5_mixin
  def initialize
    super
    @target_sis_sufix = '-S60-5th'
    @m_lib_folder = 'S60_5'
    as_v5
  end
end

class S60_5_OS < S60_3_OS
  include S60_5_mixin
  def initialize
    super
    @target_sis_sufix = '-S60-5th-OS'
    @m_lib_folder = 'S60_5-OS'
    as_v5
  end
end

class S60_5_DC < S60_3_DC
  include S60_5_mixin
  def initialize
    super
    @target_sis_sufix = '-S60-5th-DC'
    @m_lib_folder = 'S60_5'
    as_v5
  end
end

def build
  Buildall.new().build
end


