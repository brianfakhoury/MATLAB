fid = fopen('erta.txt')

a = zeros(64,128);
count = 1;
for i=1:64
    b = fgetl(fid)
    c = reshape(b,128,1);
    d = hex2dec(c);
    a(i,:) = d
end

image(a,'CDataMapping','scaled');

fclose(fid);
