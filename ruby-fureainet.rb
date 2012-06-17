$KCODE = "SJIS"

class FureaiHtml
	require 'date'
	SAVE_PATH = './html/' # need slash('/')
	BASE_DOM = 'fureai-net.city.kawasaki.jp'
	BASE_PATH = '/fureai/sw/sw3400.do?useSetubi=__SETSUBI__&useSisetuNow=__SISETSUNOW__&riyoubi=__RIYOUBI__&riyoubiNow=__RIYOUBINOW__&useSisetu=__SISETSU__&kasidasiJikanFlg=2&sisetu=1&setubi=020&viewDate=__DATE__'
	DATE_S = '%2F'
	def initialize(date)
		raise 'date is not Date class' if !date.is_a?(Date)
		@date = date
		#@setsubi = nil
		#@sisetsu = nil
		#@coatname = nil
		#@filename = nil
		#@html = nil
		set_old_html
	end
	def formated_date(date)
		raise 'wrong argument type!' if !date.is_a?(Date)
		return sprintf("%04d", date.year.to_i) + DATE_S + sprintf("%02d", date.month.to_i) + DATE_S + sprintf("%02d", date.day.to_i)
	end
	def get_url
		raise 'this class must be called from child class!' \
			if @sisetsu.nil? or @setsubi.nil?
		date = formated_date(@date)
		url = BASE_PATH.gsub(/__SETSUBI__/, @setsubi).gsub(/__SISETSUNOW__/, @sisetsu).gsub(/__SISETSU__/, @sisetsu).gsub(/__RIYOUBI__/, date).gsub(/__RIYOUBINOW__/, date).gsub(/__DATE__/, date)
	end
	def url
		get_url
	end
	def domain
		BASE_DOM
	end
	def save
		raise 'set html in this class before save' if @html.nil?
		File.open(SAVE_PATH + self.filename, "w") do |f|
			f.print(@html)
		end
	end
	def filename
		raise 'this class must be call from child class!' if @coatname.nil?
		return @filename if @filename
		return @coatname + '_' + @date.strftime("%y%m%d") + '.html'
	end
	def set_old_html
		if File.exist?(SAVE_PATH + self.filename) then
			@old_html = File.open(SAVE_PATH + self.filename).read
		else
			@old_html = ''
		end
		set_old_data
		@old_html
	end
	def set_old_data
		@old_data = parse(@old_html)
	end
	def parse(html)
		return '' if html.to_s.size < 1
		html = html.match(%r!<table border="1" summary="‹ó‚«î•ñˆê——" class="list_mb">(.*?)</table>!m).to_a[1].gsub!(/\n|\r|\s\s+/, '').split(%r!</tr>\s*<tr>!).map!{|row| row.gsub!(%r!<tr>|</tr>|<br>!, ''); row.split(%r!</td><td!) }
		time_ary = html.shift.each{|col| col.gsub!(%r!^[^>]*>|</td>!, '') }
		time_ary.shift
		rslt = Hash.new
		html.each do |row|
			if row[0].match(/<span class=/) then
				holiday = true
			else
				holiday = false
			end
			list = Hash.new()
			date = Date.strptime(Time.now.year.to_s + '/' + row.shift.gsub!(%r!<[^>]*>!, ''), "%Y/%mŒŽ%d“ú")
			time_ary.each do |time|
				if row.shift.match(/class="data_aki"/) then
					list[time] = true
				else
					list[time] = false
				end
			end
			rslt[date] = [list, holiday]
		end
		rslt
	end
	def html=(html)
		set_html(html)
	end
	def set_html(html)
		@html = html
		@data = parse(html)
	end
	def have_room?
		result = []
		@data.each do |date, value|
			holiday = value[1]
			list = value[0]
			if holiday then
				list.each do |time, room|
					if room and @old_data.size < 1 then
						result << [date, time, true]
					elsif room and !@old_data[date][0][time] then
						result << [date, time, true]
					end
				end
			end
		end
		result
	end
	attr_reader(:html, :old_html, :data, :old_data, :name)
end

class Downloader
	require 'net/https'
	Net::HTTP.version_1_2
	INTERVAL_TIME = 10
	PROXY_ADDR = ''
	PROXY_PORT = 8080
	USE_PROXY = false
	MAX_RETRY = 10
	RETRY_INTERVAL = 5
	def initialize(pages = nil)
		@pages = pages
		@https = make_https(FureaiHtml::BASE_DOM, 443, PROXY_ADDR, PROXY_PORT)
		@https.open_timeout = 60
		@https.read_timeout = 60
		@https.use_ssl = true
		@https.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end
	def make_https(domain, port, proxy_addr = nil, proxy_port = nil)
		if USE_PROXY then
			https = Net::HTTP.new(domain, port, proxy_addr, proxy_port)
		else
			https = Net::HTTP.new(domain, port)
		end
		https
	end
	def pages=(pages)
		raise 'eregal pages set' if !pages.is_a?(Array)
		@pages = pages
	end
	def start
		raise 'download pages are not set' if @pages.nil?
		@pages.each do |page|
			counter = 1
			res = nil
			begin
				@https.start
				res = @https.get(page.url)
				if res.nil? then
					page.html = ''
				else
					page.html = res.body.gsub(/(\r\n|\r|\n){2}/, "\n").gsub(/\n\s+\n/, "\n")
				end
				page.save
			rescue
				if (counter += 1) < MAX_RETRY then
					print $!, "\n"
					@https.finish
					sleep(RETRY_INTERVAL)
					retry
				end
			ensure
				@https.finish
			end
			sleep(1)#INTERVAL_TIME)
		end
		@pages
	end
end

class CoatChecker

end

class TodorokiHtml < FureaiHtml
	NAME = '“™X—Í'
	def initialize(date)
		@name = NAME
		@setsubi = '10'
		@sisetsu = '008'
		@coatname = 'TODOROKI'
		super(date)
	end
end
class DaishiHtml < FureaiHtml
	NAME = '‘åŽt'
	def initialize(date)
		@name = NAME
		@setsubi = '07'
		@sisetsu = '007'
		@coatname = 'DAISHI'
		super(date)
	end
end
class FujimiHtml < FureaiHtml
	NAME = '•xŽmŒ©'
	def initialize(date)
		@name = NAME
		@setsubi = '08'
		@sisetsu = '007'
		@coatname = 'FUJIMI'
		super(date)
	end
end
class MarienHtml < FureaiHtml
	NAME = 'ƒ}ƒŠƒGƒ“'
	def initialize(date)
		@name = NAME
		@setsubi = '12'
		@sisetsu = '012'
		@coatname = 'MARIEN'
		super(date)
	end
end
class NishisugaHtml < FureaiHtml
	NAME = '¼›'
	def initialize(date)
		@name = NAME
		@setsubi = '03'
		@sisetsu = '010'
		@coatname = 'NISHISUGA'
		super(date)
	end
end
class TonbiHtml < FureaiHtml
	NAME = '‚Æ‚ñ‚Ñ'
	def initialize(date)
		@name = NAME
		@setsubi = '04'
		@sisetsu = '010'
		@coatname = 'TONBI'
		super(date)
	end
end

date = Date.parse(ARGV.shift)
pages = [TodorokiHtml.new(date), FujimiHtml.new(date), DaishiHtml.new(date), MarienHtml.new(date)]
pages = Downloader.new(pages).start
pages.each do |page|
	print [page.name, page.have_room?].join(':'), "\n"
end