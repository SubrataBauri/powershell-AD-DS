# Powershell module pre-installed
# puppet module install puppetlabs-powershell --version 2.1.5

# Display message 
  notify { 'PowershellScript': 
    message => 'Run Powershell script for managing DNS zones and records' 
  }

  # need to change this to pull file from version control (if we use it, otherwise will be pulled from puppet master)
  # https://forge.puppet.com/puppetlabs/vcsrepo#git
  file { 'DNSScript.ps1':
    ensure  => file,
    content => file('C:\Users\username\Desktop\DNSScript.ps1' ),
    path    => 'C:\Users\username\Desktop\PowerShellScript.ps1',
  }

  # this dnsrecord csv file will come from source control OR will be pulled from puppet master
  # this is just a sample code for fetch
  file { 'dnsrecords.csv':
    ensure  => file,
    content => file('C:\Users\username\Desktop\dnsrecords.csv' ),
    path    => 'C:\Users\username\Desktop\dnsrecords.csv',
  }

  # Run the powershell script using puppet powershell module
  exec { "Run powershell script":
    command   => '& C:/Users/username/Desktop/PowerShellScript.ps1',
    provider  => powershell,
  }

