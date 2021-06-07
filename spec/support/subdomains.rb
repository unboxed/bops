def local_virtual_host
    ENV['LOCAL_VIRTUAL_HOST'] || 'lvh.me'
end

def switch_to_subdomain(subdomain)
    # lvh.me always resolves to 127.0.0.1
    Capybara.app_host = "http://#{subdomain}.#{local_virtual_host}"
end

def switch_to_main_domain
    Capybara.app_host = "http://#{local_virtual_host}"
end
