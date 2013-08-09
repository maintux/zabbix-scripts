#!/usr/bin/ruby1.9.1

require "zabbixapi"
require "pp"

zbx = ZabbixApi.connect(
  :url => 'http://zabbix_host/zabbix/api_jsonrpc.php',
  :user => 'admin',
  :password => 'password'
)

colors = [[152, 100, 0],[50, 200, 200],[153, 0, 30],[0, 0, 100],[100, 150, 0],[130, 0, 150],[0, 100, 150],[200, 100, 50],[0, 100, 0]]

template_id = zbx.templates.get_id(:host => ARGV[0]).to_i
host_ids = zbx.query({:method=>"host.get",:params=>{:output=>"extend",:templateids=>[template_id]}}).collect{|host| host['hostid']}.compact
pp host_ids
if host_ids.any?
  ["Processor load","Free Memory"].each do |item_name|
  item_ids = zbx.items.get_full_data(:name=>item_name).collect{|item| item['itemid'] if host_ids.include?(item['hostid'])}.compact
  pp item_ids
  if item_ids.any?
    gitems = []
    item_ids.each_with_index do |item_id,index| 
      gitems << {
        :itemid => item_id,
        :drawtype => "0",
        :calc_fnc => "2",
        :type => "0",
        :periods_cnt => "5",
        :color => colors[index].map{|c| c.to_s(16).rjust(2,'0')}.join,
        :yaxisside => "0"
      }
    end    
    zbx.graphs.create_or_update(
      :gitems => gitems,
      :show_triggers => "1",
      :name => "#{ARGV[0]} - #{item_name}",
      :width => "900",
      :height => "200",
      
    )
  end
  end
end
