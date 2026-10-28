"""Inspect alpha only; write region metadata, never alter source pixels."""
from pathlib import Path
import json
import argparse
import numpy as np
from PIL import Image

GRIDS = {'buildings':(5,2),'vegetation':(5,3),'village-props':(5,3),'pets':(5,2),'ocean':(5,3),'heroes':(4,3),'residents':(5,2),'ocean-bed':(5,2),'interiors':(2,3),'trees-pair':(2,1),'details':(5,3),'kraken-set':(3,1),'gates':(3,1),'household':(3,2)}

def components(mask):
    parent=[]; bounds=[]; sizes=[]; previous=[]
    def root(i):
        while parent[i]!=i:
            parent[i]=parent[parent[i]]; i=parent[i]
        return i
    for y,row in enumerate(mask):
        edges=np.flatnonzero(np.diff(np.r_[False,row,False])); runs=[]; j=0
        for left,right in zip(edges[::2],edges[1::2]):
            ix=len(parent); parent.append(ix); bounds.append([int(left),y,int(right),y+1]); sizes.append(int(right-left))
            while j<len(previous) and previous[j][1]<left:j+=1
            k=j
            while k<len(previous) and previous[k][0]<=right:
                old=root(previous[k][2]); new=root(ix)
                if old!=new:
                    parent[old]=new; a=bounds[new]; b=bounds[old]
                    bounds[new]=[min(a[0],b[0]),min(a[1],b[1]),max(a[2],b[2]),max(a[3],b[3])]; sizes[new]+=sizes[old]
                k+=1
            runs.append((left,right,ix))
        previous=runs
    return sorted([(sizes[i],bounds[i]) for i in range(len(parent)) if root(i)==i and sizes[i]>300],reverse=True)

def inspect(directory):
    output={}
    for name,(cols,rows) in GRIDS.items():
        path=directory/(name+'.png')
        if not path.exists():continue
        image=Image.open(path).convert('RGBA'); pixels=np.array(image); width,height=image.size
        if name=='interiors':
            output[name]=[[int(x*width/cols)+3,int(y*height/rows)+3,int(width/cols)-6,int(height/rows)-6] for y in range(rows) for x in range(cols)]
            continue
        if pixels[:,:,3].min()>200:
            print('OPAQUE',name);continue
        entries={}
        for area,(left,top,right,bottom) in components(pixels[:,:,3]>96):
            col=min(cols-1,int((left+right)*0.5/width*cols)); row=min(rows-1,int((top+bottom)*0.5/height*rows)); slot=row*cols+col
            if slot not in entries:
                entries[slot]=[left,top,right-left,bottom-top]
        print(name,'regions',len(entries),'expected',cols*rows)
        output[name]=[entries.get(i,[]) for i in range(cols*rows)]
    # Rain-tree and pink canopy overlap in the original broad atlas. Their
    # separate authored source owns these two runtime species instead.
    if 'vegetation' in output:
        output['vegetation'][1]=[270,125,390,331]
        output['vegetation'][2]=[646,70,311,383]
    output['fire-demon']=[[1620,90,330,307]]
    stone=Image.open(directory.parent/'realms/basalt-floor-v2.png')
    output['stone-floor']=[[0,0,*stone.size]]
    return output

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--write',action='store_true');args=parser.parse_args()
    directory=Path(__file__).resolve().parent.parent/'assets/authored/realistic'
    result=inspect(directory)
    print(json.dumps(result))
    if args.write:(directory/'regions.json').write_text(json.dumps(result,indent=2)+'\n')
