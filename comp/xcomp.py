import sys
from   functools  import reduce

def print_dist(data):
    dist = calc_dist(data)
    print("Distribution among", len(data), "items:")
    for item, frequency in sorted(dist.items(), key = snd, reverse=True):
        print("{:>7.2f}% |".format(frequency / len(data) * 100), item)
        
def print_weights(data):
    dist = calc_dist(data)
    print("Weighting among", len(data), "items:")
    total = sum(map(lambda x: x[0] * x[1], dist.items()))
    for item, frequency in sorted(dist.items(), key = snd, reverse=True):
        print("{:>7.2f}% |".format(frequency * item / total * 100), item)
        
def calc_dist(data):
    dist = {}
    for value in data:
        if value in dist:
            dist[value] += 1
        else:
            dist[value] = 1
    return dist
    
def filt(a,b,c):
    return a & b
    
def bit_filt(gfx):
    out = [0, 0, 0, 0]
    for i in range(4, len(gfx), 2):
        a = gfx[i-1]
        b = gfx[i-3]
        c = gfx[i-3] >> 1
        out.append(filt(a,b,c))
    return out
    
def bitsof(xs):
    return reduce(
        lambda a, b: a + b,
        map(lambda x: [(x >> i) & 1 for i in range(7,-1,-1)], xs)
    )
    
def make_runs(xs, max_len=256):
    i = 0
    runs = []
    while i < len(xs):
        n = count_sames(xs[i:])
        while n > max_len:
            runs.append((max_len, xs[i]))
            n -= max_len
        if n != 0:
            runs.append((n, xs[i]))
        i += n
    return runs
    
def bit_patterns(gfx):
    bits = bitsof(gfx)
    pats = [[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0]]
    i = 24
    while i < len(bits):
        bit = bits[i]
        inp = (bits[i-1] << 2 ) | (bits[i-16] << 1) | (bits[i-17])
        pats[inp][bit] += 1
        i += 1
    return pats
    
def deltas(xs, ys):
    return list(map(lambda x: x[0] ^ x[1], zip(xs, ys)))

def count_sames(xs):
    if len(xs) <= 1:
        return len(xs)
    else:
        i = 1
        x = xs[0]
        while i < len(xs) and xs[i] == x:
            i += 1
        return i
    
fst = lambda tup: tup[0]
snd = lambda tup: tup[1]
    
def rle(data):
    runs = make_runs(data, 127)
    print_weights(list(map(fst,runs)))
    output = bytearray()
    i = 0
    while i < len(runs):
        if runs[i][0] < 2:  # We don't actually have a useful run.
            nonrun = []
            while runs[i][0] < 2 and len(nonrun) < 127:
                nonrun.extend([runs[i][1]] * runs[i][0])
                i += 1
            output.append(len(nonrun))
            output.extend(nonrun)
        else:
            output.append(0x80 | (runs[i][0]))
            output.append(runs[i][1])
            i += 1
    output.append(0)
        
    return output
    
if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: xcomp source dest')
    else:
        data = open(sys.argv[1], 'rb').read()
        
        output = rle(data)
        
        outfile = open(sys.argv[2], 'wb')
        outfile.write(output)