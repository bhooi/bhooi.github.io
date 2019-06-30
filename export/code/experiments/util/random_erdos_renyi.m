function A = random_erdos_renyi(n, p)

A = sparse(triu(double(rand(n) < p),1));
A = A + A';

end