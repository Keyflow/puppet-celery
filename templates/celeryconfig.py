broker_url = "<%= @broker_prefix %>://<% if @broker_user -%><%= @broker_user %><% if @broker_password -%>:<%= @broker_password %><% end -%><% end -%>@<%= @broker_host %><% if @broker_port %>:<%= @broker_port %><% end -%><% if @broker_vhost -%>/<%= @broker_vhost %><% end -%>"
<% if @backend_url -%>
result_backend = "<%= @backend_url %>"
<% else -%>
result_backend = "<%= @backend_prefix %>://<% if @backend_user -%><%= @backend_user %><% if @backend_password -%>:<%= @backend_password %><% end -%><% end -%>@<%= @backend_host %><% if @backend_port %>:<%= @backend_port %><% end -%><% if @backend_suffix -%>/<%= @backend_suffix %><% end -%>"
<% end -%>
