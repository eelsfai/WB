clear variables
close all

% web scrapping block background info
% https://www.scrapehero.com/how-to-prevent-getting-blacklisted-while-scraping/
% https://www.marketwatch.com/robots.txt


%%
warning('off','all');
fname = ['List of Investable companies ',date,' .txt'];
fname2 = ['List of non-Investable companies ',date,' .txt'];
fileID = fopen(fname, 'at' );
fileID2 = fopen(fname2, 'at' );

c = ['Company','	EpSY1	EpSY2	EpSY3	EpSY4	EpSY5	MarketCap	Equity	Slope	P/E	RevY1	RevY2	RevY3	RevY4	RevY5	SlopeR		ProfY1	ProfY2	ProfY3	ProfY4	ProfY5	currency	RoEY1	RoEY2	RoEY3	RoEY4	RoEY5		PMy1		PMy2		PMy3		PMy4		PMy5	Yield	NetIncomePerMarketCap'];
fprintf(fileID,c);
c = ['Company','	EpSY1	EpSY2	EpSY3	EpSY4	EpSY5	MarketCap	Equity	Slope	P/E	RevY1	RevY2	RevY3	RevY4	RevY5	SlopeR		ProfY1	ProfY2	ProfY3	ProfY4	ProfY5	currency	RoEY1	RoEY2	RoEY3	RoEY4	RoEY5		PMy1		PMy2 		PMy3		PMy4		PMy5	Yield	NetIncomePerMarketCap'];
fprintf(fileID2,c);

options = weboptions('Timeout', 90);

% https://www.nasdaq.com/screening/company-list.aspx
company{1} = loadCompaniesNASDAQ;
company{2} = loadCompaniesNYSE;
company{3} = loadCompaniesAMEX;
company{4} = loadCompaniesCanada; % https://api.tmxmoney.com/en/migreport/search

for x=1:size(company,2)
    for j=1:1:size(company{x},1)
        
        try
            %% read Income Statement
            company{x}(j,:)
            url = ['http://www.marketwatch.com/investing/stock/',company{x}(j,:),'/financials/'];
            url = strrep(url,' ','');
            %     query  = 'urlread2';
            %     params = {'term' query};
            %     queryString = http_paramsToString(params,1);
            %     url = [url '?' queryString];
            
            % Retry if crash
            for i = 1:5
                try
                    %             [html,extras] = urlread2(url);
                    txt = webread(url,options);
                    break;  % Break out of the i-loop on success
                catch ME
                    disp(ME);
                    pause(3);
                    fprintf('Retrying...\n');
                end
            end
            %html = urlread(url_string);
            % Use regular expressions to remove undesired markup.
            txt = regexprep(txt,'<script.*?/script>','');
            txt = regexprep(txt,'<style.*?/style>','');
            txt = regexprep(txt,'<.*?>',' ');
            Income_Statement = regexprep(txt,'&nbsp;','');
            k = strfind(Income_Statement, '  Net Income ');
            if ~isempty(k)
                text = Income_Statement(k(1)+15:k(1)+95);
                text = strrep(text,'M','M ');
                text = strrep(text,'B','B ');
                text = strrep(text,')','');
                text = strrep(text,'(','-');
                text = strsplit(text);
                
                for i =1:1:5
                    if text{1,i+1}(end) ~= '-'
                        if text{1,i+1}(end) == 'M'
                            NetIncome(i) = str2double(text{1,i+1}(1:end-1))*1000000;
                        elseif text{1,i+1}(end) == 'B'
                            NetIncome(i) = str2double(text{1,i+1}(1:end-1))*1000000000;
                        elseif text{1,i+1}(end) ~= 'B' && text{1,i+1}(end) ~= 'M'
                            NetIncome(i) = str2double(strrep(text{1,i+1},',','')); %Remove comma from number
                        end
                    end
                end
                
                
                Income_Statement = regexprep(txt,'&nbsp;',' ');
                k = strfind(Income_Statement, ' EPS (Diluted) ');
                text = Income_Statement(k+15:k+150);
                
                text = strsplit(text);
                text = strrep(text,')','');
                text = strrep(text,',','');
                text = strrep(text,'(','-');
                
                for i =1:1:5
                    if text{1,i+1}(end) ~= '-'
                        EpS(i) = str2double(text{1,i+1}(1:end));
                    end
                end
                
                k = strfind(Income_Statement, ' Sales/Revenue');
                if ~isempty(k)
                    text = Income_Statement(k(1)+15:k(1)+95);
                    text = strrep(text,'M','M ');
                    text = strrep(text,'B','B ');
                    text = strrep(text,')','');
                    text = strrep(text,'(','-');
                    text = strsplit(text);
                    
                    for i =1:1:5
                        if text{1,i+1}(end) ~= '-'
                            if text{1,i+1}(end) == 'M'
                                Rev(i) = str2double(text{1,i+1}(1:end-1))*1000000;
                            elseif text{1,i+1}(end) == 'B'
                                Rev(i) = str2double(text{1,i+1}(1:end-1))*1000000000;
                            elseif text{1,i+1}(end) ~= 'B' && text{1,i+1}(end) ~= 'M'
                                Rev(i) = str2double(strrep(text{1,i+1},',','')); %Remove comma from number
                            end
                        end
                    end
                    
                    PM = 100*NetIncome./Rev;
                    
                    %% Currency
                    k = strfind(Income_Statement, 'All values ');
                    currency = Income_Statement(k+11:k+14);
                    %% Read Balance Sheet
                    clear text
                    
                    url = ['http://www.marketwatch.com/investing/stock/',company{x}(j,:),'/financials/balance-sheet'];
                    url = strrep(url,' ','');
                    %             query  = 'urlread2';
                    %             params = {'term' query};
                    %             queryString = http_paramsToString(params,1);
                    %             url = [url '?' queryString];
                    
                    for i = 1:5
                        try
                            %                     [html,extras] = urlread2(url);
                            txt = webread(url,options);
                            break;  % Break out of the i-loop on success
                        catch ME
                            disp(ME);
                            pause(3);
                            fprintf('Retrying...\n');
                        end
                    end
                    %html = urlread(url_string);
                    % Use regular expressions to remove undesired markup.
                    txt = regexprep(txt,'<script.*?/script>','');
                    txt = regexprep(txt,'<style.*?/style>','');
                    txt = regexprep(txt,'<.*?>',' ');
                    BalanceSheet = regexprep(txt,'&nbsp;','');
                    k = strfind(BalanceSheet, ' Total Equity ');
                    % Multiple k appear, pick right one
                    for i=1:size(k,2)
                        if ~strcmp(BalanceSheet(k(i)+14:k(i)+34),'Securities Investment')
                            text = BalanceSheet(k(i)+15:k(i)+85);
                            text = strrep(text,'M','M ');
                            text = strrep(text,'B','B ');
                            text = strrep(text,')','');
                            text = strrep(text,'(','-');
                            text = strrep(text,',','');
                            text = strsplit(text);
                            if text{1,3}(end)~='%'&&text{1,3}(end)~='-'
                                break
                            end
                        end
                    end
                    
                    for i =1:1:5
                        if text{1,i+1}(end) ~= '-'
                            if text{1,i+1}(end) == 'M'
                                TotalEquity(i) = str2double(text{1,i+1}(1:end-1))*1000000;
                            elseif text{1,i+1}(end) == 'B'
                                TotalEquity(i) = str2double(text{1,i+1}(1:end-1))*1000000000;
                            elseif text{1,i+1}(end) ~= 'B' && text{1,i+1}(end) ~= 'M'
                                TotalEquity(i) = str2double(text{1,i+1}(1:end));
                            end
                        end
                    end
                    
                    
                    %% read Cash Flow
                    url = ['http://www.marketwatch.com/investing/stock/',company{x}(j,:),'/financials/cash-flow'];
                    url = strrep(url,' ','');
                    %             query  = 'urlread2';
                    %             params = {'term' query};
                    %             queryString = http_paramsToString(params,1);
                    %             url = [url '?' queryString];
                    
                    for i = 1:5
                        try
                            %                     [html,extras] = urlread2(url);
                            txt = webread(url,options);
                            break;  % Break out of the i-loop on success
                        catch ME
                            disp(ME);
                            pause(3);
                            fprintf('Retrying...\n');
                        end
                    end
                    
                    %html = urlread(url);
                    % Use regular expressions to remove undesired markup.
                    txt = regexprep(txt,'<script.*?/script>','');
                    txt = regexprep(txt,'<style.*?/style>','');
                    txt = regexprep(txt,'<.*?>',' ');
                    Income_Statement = regexprep(txt,'&nbsp;','');
                    k = strfind(Income_Statement, 'Change in Capital Stock');
                    text = Income_Statement(k+24:k+120);
                    text = strrep(text,'M','M ');
                    text = strrep(text,'B','B ');
                    text = strrep(text,')','');
                    text = strrep(text,'(','-');
                    text = strrep(text,',','');
                    text = strsplit(text);
                    
                    for i =1:1:5
                        if text{1,i+1}(end) ~= '-'
                            if text{1,i+1}(end) == 'M'
                                changeInCapitalStock(i) = str2double(text{1,i+1}(1:end-1))*1000000;
                            elseif text{1,i+1}(end) == 'B'
                                changeInCapitalStock(i) = str2double(text{1,i+1}(1:end-1))*1000000000;
                            elseif text{1,i+1}(end) ~= 'B'&&text{1,i+1}(end) ~= 'M'
                                changeInCapitalStock(i) = str2double(text{1,i+1}(1:end));
                            end
                        end
                    end
                    
                    
                    
                    %% read Key Statistics
                    url = ['http://www.marketwatch.com/investing/stock/',company{x}(j,:),''];
                    url = strrep(url,' ','');
                    %             query  = 'urlread2';
                    %             params = {'term' query};
                    %             queryString = http_paramsToString(params,1);
                    %             url = [url '?' queryString];
                    
                    for i = 1:5
                        try
                            %                     [html,extras] = urlread2(url);
                            txt = webread(url,options);
                            break;  % Break out of the i-loop on success
                        catch ME
                            disp(ME);
                            pause(3);
                            fprintf('Retrying...\n');
                        end
                    end
                    %html = urlread(url);
                    % Use regular expressions to remove undesired markup.
                    txt = regexprep(txt,'<script.*?/script>','');
                    txt = regexprep(txt,'<style.*?/style>','');
                    txt = regexprep(txt,'<.*?>',' ');
                    KeyStats = regexprep(txt,'&nbsp;','');
                    k = strfind(KeyStats, 'P/E Ratio');
                    text = KeyStats(k+10:k+40);
                    PoverE = str2double(text);
                    
                    k = strfind(KeyStats, 'Yield');
                    text = strrep(KeyStats(k+10:k+35),'%','');
                    Yield = str2double(text);
                    
                    k = strfind(KeyStats, 'Market Cap');
                    text = KeyStats(k+10:k+40);
                    text = strrep(text,'$','');
                    text = strrep(text,' ','');
                    MarketCap= [];
                    if strfind(text,'M')
                        MarketCap = str2double(text(1:end-2))*1000000;
                    elseif strfind(text,'B')
                        MarketCap = str2double(text(1:end-2))*1000000000;
                    elseif strfind(text,'K')
                        MarketCap = str2double(text(1:end-2))*1000;
                    end
                    
                    try
                        NetIncomePerMarketCap = 100*NetIncome(end)/MarketCap;
                    catch
                        NetIncomePerMarketCap = 'NAN';
                    end
                    
                    %% Conditions
                    if ~isempty(MarketCap)
                        C(1) = MarketCap<3*(TotalEquity(5)); %Margin of Safety
                        year = [1 2 3 4 5];
                        p = polyfit(year,EpS,1);
                        f = polyval(p,year);
                        C(2) = f(2)>f(1); % Positive slope Eps
                        C(3) = (EpS(5)>=0.9*EpS(4))&&(EpS(4)>=0.9*EpS(3))&&(EpS(3)>=0.9*EpS(2))&&(EpS(2)>=0.9*EpS(1)); % EpS stable growth
                        C(4) = (EpS(5)>=0)&&(EpS(4)>0)&&(EpS(3)>0)&&(EpS(2)>0)&&(EpS(1)>0); % EpS positive
                        if isempty(PoverE)
                            PoverE = NaN;
                        end
                        C(5) = PoverE<20;
                        C(6) = MarketCap>10*10e6;
                        C(7) = (Rev(5)>=0.9*Rev(4))&&(Rev(4)>=0.9*Rev(3))&&(Rev(3)>=0.9*Rev(2))&&(Rev(2)>=0.9*Rev(1)); % Revenue stable growth
                        pR = polyfit(year,Rev,1);
                        fR = polyval(pR,year);
                        C(8) = (NetIncome(5)>=0.9*NetIncome(4))&&(NetIncome(4)>=0.9*NetIncome(3))&&(NetIncome(3)>=0.9*NetIncome(2))&&(NetIncome(2)>=0.9*NetIncome(1)); % NetIncome stable growth
                        %% print
                        if C(1)&&C(2)&&C(3)&&C(4)&&C(5)&&C(6)&&C(7)&&C(8)
                            c = ['\n','',company{x}(j,:),'','	',num2str(EpS(1)),'	',num2str(EpS(2)),'	',num2str(EpS(3)),'	',num2str(EpS(4)),'	',num2str(EpS(5)),'	',num2str(MarketCap/1000000),'M		',num2str(TotalEquity(5)/1000000),'M	',num2str((f(2)-f(1))),'	',num2str(PoverE),'	',num2str(Rev(1)/1000000),'M	',num2str(Rev(2)/1000000),'M	',num2str(Rev(3)/1000000),'M	',num2str(Rev(4)/1000000),'M	',num2str(Rev(5)/1000000),'M	',num2str((fR(2)-fR(1))),'	',num2str(NetIncome(1)/1000000),'M	',num2str(NetIncome(2)/1000000),'M	',num2str(NetIncome(3)/1000000),'M	',num2str(NetIncome(4)/1000000),'M	',num2str(NetIncome(5)/1000000),'M	',currency,' 		',num2str(100*NetIncome(1)/TotalEquity(1)),'	',num2str(100*NetIncome(2)/TotalEquity(2)),'	',num2str(100*NetIncome(3)/TotalEquity(3)),'	',num2str(100*NetIncome(4)/TotalEquity(4)),'	',num2str(100*NetIncome(5)/TotalEquity(5)),'	',num2str(PM),'	',num2str(Yield),'%% ',num2str(NetIncomePerMarketCap),'% '];
                            fprintf(fileID,c);
                        else
                            c = ['\n','',company{x}(j,:),'','	',num2str(EpS(1)),'	',num2str(EpS(2)),'	',num2str(EpS(3)),'	',num2str(EpS(4)),'	',num2str(EpS(5)),'	',num2str(MarketCap/1000000),'M		',num2str(TotalEquity(5)/1000000),'M	',num2str((f(2)-f(1))),'	',num2str(PoverE),'	',num2str(Rev(1)/1000000),'M	',num2str(Rev(2)/1000000),'M	',num2str(Rev(3)/1000000),'M	',num2str(Rev(4)/1000000),'M	',num2str(Rev(5)/1000000),'M	',num2str((fR(2)-fR(1))),'	',num2str(NetIncome(1)/1000000),'M	',num2str(NetIncome(2)/1000000),'M	',num2str(NetIncome(3)/1000000),'M	',num2str(NetIncome(4)/1000000),'M	',num2str(NetIncome(5)/1000000),'M	',currency,' 		',num2str(100*NetIncome(1)/TotalEquity(1)),'	',num2str(100*NetIncome(2)/TotalEquity(2)),'	',num2str(100*NetIncome(3)/TotalEquity(3)),'	',num2str(100*NetIncome(4)/TotalEquity(4)),'	',num2str(100*NetIncome(5)/TotalEquity(5)),'	',num2str(PM),'	',num2str(Yield),'%% ',num2str(NetIncomePerMarketCap),'% '];
                            fprintf(fileID2,c);
                        end
                        
                    end
                end
            end
        end
    end
end
fclose(fileID);
fclose(fileID2);
