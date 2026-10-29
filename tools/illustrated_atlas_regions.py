"""Read-only alpha inspection; metadata authoring does not edit image pixels."""
from pathlib import Path
import argparse
import json
import sys
import numpy as np
from PIL import Image
sys.dont_write_bytecode=True
from realistic_atlas_regions import components

GRIDS = {'buildings':(5,2),'vegetation':(5,3),'village-props':(5,3),
    'pets':(5,2),'ocean':(5,3),'heroes':(4,3),'residents':(5,2),
    'ocean-bed':(5,2),'interiors':(2,3),'trees-pair':(2,1),
    'details':(5,3),'kraken-set':(3,1),'gates':(3,1),'household':(3,2),
    'demon-bosses':(5,2),'demon-minions':(5,2),'realm-props':(5,2)}

def inspect(directory):
    result={}
    for name,(cols,rows) in GRIDS.items():
        path=directory/(name+'.png')
        if not path.exists(): continue
        image=Image.open(path).convert('RGBA')
        width,height=image.size
        alpha=np.array(image)[:,:,3]
        if name=='interiors':
            result[name]=[[int(x*width/cols)+3,int(y*height/rows)+3,
                int(width/cols)-6,int(height/rows)-6] for y in range(rows) for x in range(cols)]
            continue
        if alpha.min()>200: raise ValueError(name+' must have transparent alpha')
        entries={}
        for area,(left,top,right,bottom) in components(alpha>96):
            col=min(cols-1,int((left+right)*0.5/width*cols))
            row=min(rows-1,int((top+bottom)*0.5/height*rows))
            slot=row*cols+col
            if slot not in entries: entries[slot]=[left,top,right-left,bottom-top]
        missing=set(range(cols*rows))-set(entries)
        # These two overlapping crowns are unused: separate trees-pair owns them.
        if name=='vegetation':
            for slot in [1,2]:
                entries.setdefault(slot,[int(slot*width/cols),0,int(width/cols),int(height/rows)])
            missing-=set([1,2])
        if missing: raise ValueError(f'{name}: missing cells {sorted(missing)}')
        result[name]=[entries[i] for i in range(cols*rows)]
        print(f'{name}: {len(entries)} regions')
    if 'demon-minions' in result: result['fire-demon']=[result['demon-minions'][4]]
    stone=directory/'stone-floor.png'
    if stone.exists(): result['stone-floor']=[[0,0,*Image.open(stone).size]]
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--write',action='store_true')
    args=parser.parse_args()
    directory=Path(__file__).resolve().parent.parent/'assets/authored/illustrated'
    result=inspect(directory)
    if args.write: (directory/'regions.json').write_text(json.dumps(result,indent=2)+'\n')
