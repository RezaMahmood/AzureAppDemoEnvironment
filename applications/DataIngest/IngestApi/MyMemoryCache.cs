using System;
using Microsoft.Extensions.Caching.Memory;

namespace IngestApi
{
    public class MyMemoryCache
    {
        public MemoryCache Cache { get; private set; }

        public MyMemoryCache()
        {
            this.Cache = new MemoryCache(new MemoryCacheOptions
            {
                SizeLimit = 1024
            });
        }
    }
}
