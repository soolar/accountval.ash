import <CFStat.ash>;
import <zlib.ash>;

int item_price(item it)
{
	itemdata itdata = salesVolume(it.to_int());
	if(itdata.amountsold <= 0)
	{
		int lowest_mall = mall_price(it);
		// none have sold, first let's try finding if any foldables have sold
		foreach foldable in get_related(it, "fold")
		{
			if(mall_price(foldable) < lowest_mall)
				lowest_mall = mall_price(foldable);
			itemdata folddata = salesVolume(foldable.to_int());
			// if a foldable has sold, it's probably the cheapest one
			// and if it's not, you might be able to sell it to chumps anyway
			if(folddata.amountsold > 0)
				return folddata.avePrice;
		}
		int mall_min = min(100, 2 * autosell_price(it));
		if(lowest_mall == mall_min || (lowest_mall < 0 && autosell_price(it) != 0))
			return autosell_price(it);
		return lowest_mall;
	}
	return itdata.avePrice;
}

void main()
{
	int [item] items;
	int [item] itemvals;
	item [int] to_sort;
	foreach it in $items[]
	{
		int amount = storage_amount(it) + closet_amount(it) + display_amount(it) +
			equipped_amount(it) + item_amount(it) + shop_amount(it);
		items[it] = amount;
	}

	string[string][string][string] map;
	file_to_map("accountval_stuff.txt", map);
	
	string[string] visit_cache;
	void visit_check(item it, string url, string find)
	{
		string page = visit_cache[url];
		if(page == "")
		{
			page = visit_url(url);
			visit_cache[url] = page;
		}

		if(page.index_of(find) != -1)
		{
			items[it] += 1;
			//print("found " + it);
		}
	}

	foreach type,f1,f2,f3 in map
	{
		switch(type)
		{
			case "i": // item containers
			{
				item container = to_item(f1);
				item contained = to_item(f2);
				int amount = items[contained];
				items[contained] -= amount;
				items[container] += amount;
				//if(amount > 0)
				//	print("found " + container);
				break;
			}
			case "b": // books
			{
				item it = to_item(f1);
				visit_check(it, "campground.php?action=bookshelf", f2);
				break;
			}
			case "p": // properties
			{
				item it = to_item(f1);
				if(get_property(f2).to_boolean() == true)
				{
					//print("found " + it);
					items[it] += 1;
				}
				break;
			}
			case "e": // eudoras
			{
				item it = to_item(f1);
				visit_check(it, "account.php?tab=correspondence", f2);
				break;
			}
			case "v": // visit url checks
			{
				item it = to_item(f1);
				visit_check(it, f2, f3);
				break;
			}
		}
	}

	foreach f in $familiars[]
	{
		if(have_familiar(f))
			items[f.hatchling] += 1;
	}


	int tocheck = 0;
	int checked = 0;
	foreach it,i in items
	{
		if(i > 0 && (it.tradeable || autosell_price(it) > 0))
			++tocheck;
	}
	int netval = my_meat() + my_closet_meat() + my_storage_meat();
	foreach it,i in items
	{
		if(i > 0)
		{
			print("Checking value of " + it + " (" + rnum(++checked) + " / " + rnum(tocheck) + ")", "blue");
			int val = item_price(it) * i;
			if(val > 0) netval += val;
			itemvals[it] = val;
			to_sort[to_sort.count()] = it;
		}
	}
	int sortval(item it)
	{
		if(itemvals[it] > 0)
			return itemvals[it];
		return 999999999999;
	}
	sort to_sort by sortval(value);
	foreach i,it in to_sort
	{
		if(itemvals[it] > 0)
			print(rnum(items[it]) + " " + it + " worth a total of " + rnum(itemvals[it]));
		else if(itemvals[it] < 0)
			print(rnum(items[it]) + " " + it + " that are straight up priceless");
	}
	print("You are worth " + rnum(netval) + " meat!");
	itemdata mr_a = salesVolume($item[Mr. Accessory].to_int());
	float mr_as = netval.to_float() / mr_a.avePrice.to_float();
	float dollars = mr_as * 10;
	print("Going by the value of a Mr. Accessory, that's $" + rnum(dollars));
}
