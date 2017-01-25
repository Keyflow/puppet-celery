broker_url = "<%= @broker_prefix %>://<% if @broker_user -%><%= @broker_user %><% if @broker_password -%>:<%= @broker_password %><% end -%>@<% end -%><%= @broker_hosts.join(',') %><% if @broker_suffix -%>/<%= @broker_suffix %><% end -%>"
<% if @backend_url -%>
result_backend = "<%= @backend_url %>"
<% else -%>
result_backend = "<%= @backend_prefix %>://<% if @backend_user -%><%= @backend_user %><% if @backend_password -%>:<%= @backend_password %><% end -%>@<% end -%><%= @backend_hosts.join(',') %><% if @backend_suffix -%>/<%= @backend_suffix %><% end -%>"
<% end -%>
<% @custom_config.keys.sort.each do |key| %>
<%= key.downcase %> = <% if ("#{@custom_config[key]}" == "undef") -%>None<% elsif @custom_config[key].kind_of?(Numeric) -%><%= @custom_config[key] %><% elsif (!!@custom_config[key] == @custom_config[key]) -%><% if @custom_config[key] -%>True<% else -%>False<% end -%><% elsif @custom_config[key].kind_of?(Array) -%><%= "#{@custom_config[key]}" %><% else -%>"<%= @custom_config[key] %>"<% end -%>
<% end %>
