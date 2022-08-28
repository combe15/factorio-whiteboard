use serde::Deserialize;
use serde_json::value::Value;
use std::collections::HashMap;

type Ingredients = HashMap<String, u64>;

#[derive(Debug, Deserialize, Clone)]
struct Recipe {
    energy_required: f64,
    ingredients: Ingredients,
    results: HashMap<String, u64>,
    expensive: bool,
    name: String,
}

fn is_ingredient_treated_as_raw(ingredient: &str) -> bool {
    match ingredient {
        "petroleum-gas" => true,
        "light-oil" => true,
        "heavy-oil" => true,
        "uranium-235" => true,
        "uranium-238" => true,
        _ => false,
    }
}

fn parse(mut v: Value) -> Option<Vec<Recipe>> {
    let v = v.as_object_mut().unwrap();
    let name = v.get("name").unwrap().as_str().unwrap().to_owned();
    if let Some(decomp) = v.get("allow_decomposition") {
        // TODO: actually allow this for some recipes (like liquefaction)
        if decomp.as_bool() == Some(false) {
            return None;
        }
    }
    if v.contains_key("expensive") {
        return Some(vec![
            parse_recipe(
                v.get_mut("expensive").unwrap().as_object_mut().unwrap(),
                true,
                name.clone(),
            ),
            parse_recipe(
                v.get_mut("normal").unwrap().as_object_mut().unwrap(),
                false,
                name,
            ),
        ]);
    } else {
        return Some(vec![parse_recipe(v, false, name)]);
    }
}

fn parse_recipe(
    recipe: &mut serde_json::Map<String, Value>,
    expensive: bool,
    name: String,
) -> Recipe {
    let mut parsed_results = HashMap::new();

    let rc = match recipe.get("result_count") {
        Some(v) => v.as_u64().unwrap_or(1),
        _ => 1,
    };
    if let Some(result) = recipe.get("result") {
        let name = result.as_str().unwrap().to_owned();
        parsed_results.insert(name, rc);
    }
    if let Some(results) = recipe.get("results") {
        for resl in results.as_array().unwrap() {
            if let Some(resl) = resl.as_object() {
                let name = resl.get("name").unwrap().as_str().unwrap().to_owned();
                let amt = resl.get("amount").unwrap().as_u64().unwrap().to_owned();
                parsed_results.insert(name, amt);
            }
            if let Some(resl) = resl.as_array() {
                let name = resl.get(0).unwrap().as_str().unwrap().to_owned();
                let amt = resl.get(1).unwrap().as_u64().unwrap().to_owned();
                parsed_results.insert(name, amt);
            }
        }
    }
    let mut ings = HashMap::new();
    if let Some(parse_ings) = recipe.get("ingredients") {
        for parse_ing in parse_ings.as_array().unwrap() {
            if let Some(parse_ing) = parse_ing.as_array() {
                let name = parse_ing.get(0).unwrap().as_str().unwrap().to_owned();
                let amt = parse_ing.get(1).unwrap().as_u64().unwrap().to_owned();
                ings.insert(name, amt);
            }
            if let Some(parse_ing) = parse_ing.as_object() {
                let name = parse_ing.get("name").unwrap().as_str().unwrap().to_owned();
                let catalyst = parse_ing
                    .get("catalyst")
                    .map(|v| v.as_u64().unwrap())
                    .unwrap_or(0);
                let amt = parse_ing.get("amount").unwrap().as_u64().unwrap() - catalyst;
                if amt > 0 {
                    // Ignore net-0 recipes (barreling)
                    ings.insert(name, amt);
                }
            }
        }
    }
    Recipe {
        energy_required: match recipe.get("energy_required") {
            Some(v) => v.as_f64().unwrap_or(0.5),
            _ => 0.5,
        },
        ingredients: ings,
        results: parsed_results,
        expensive,
        name,
    }
}

fn main() {
    let data = std::fs::read_to_string("data/recipe.json").unwrap();
    let vals: HashMap<String, Value> = serde_json::from_str(&data).unwrap();
    let mut recipes: HashMap<String, Vec<Recipe>> = HashMap::new();
    for (_k, v) in vals.into_iter() {
        if let Some(parsed) = parse(v) {
            for recipe in parsed.iter() {
                for built_item in recipe.results.keys() {
                    let ent = recipes.entry(built_item.clone()).or_insert(Vec::new());
                    ent.push(recipe.to_owned());
                }
            }
        }
    }
    for arg in std::env::args().skip(1) {
        if let Some(recipes_vec) = recipes.get(&arg) {
            for recipe in recipes_vec {
                if !recipe.expensive {
                    let mut tco: HashMap<String, f64> = HashMap::new();
                    let mut time = recipe.energy_required as f64;
                    for (k, v) in &recipe.ingredients {
                        recurse_ingredient(
                            &recipes,
                            k,
                            *v as f64,
                            recipe.expensive,
                            &mut tco,
                            &mut time,
                        )
                    }
                    println!(
                        "Raw Time: {:?}, Material: {:?}, recipe: {:?}",
                        std::time::Duration::from_secs_f64(time),
                        tco,
                        recipe
                    );
                }
            }
        }
    }
}

fn recurse_ingredient(
    recipes: &HashMap<String, Vec<Recipe>>,
    ingredient: &str,
    parent_amt: f64,
    expensive: bool,
    tco: &mut HashMap<String, f64>,
    time: &mut f64,
) {
    let mut found = false;
    if !is_ingredient_treated_as_raw(ingredient) {
        if let Some(recipes_with_product) = recipes.get(ingredient) {
            for recipe in recipes_with_product {
                if recipe.expensive == expensive && !found {
                    found = true;
                    *time += recipe.energy_required * parent_amt
                        / *recipe.results.get(ingredient).unwrap() as f64;
                    /*println!(
                        "Added {}s for {}",
                        recipe.energy_required * parent_amt
                            / *recipe.results.get(ingredient).unwrap() as f64,
                        recipe.name,
                    );*/
                    for (ing, req_amt) in &recipe.ingredients {
                        recurse_ingredient(
                            recipes,
                            ing,
                            *req_amt as f64 * parent_amt
                                / *recipe.results.get(ingredient).unwrap() as f64,
                            expensive,
                            tco,
                            time,
                        );
                    }
                }
            }
            // Use normal recipe if expensive doesn't exist
            if !found && expensive {
                for recipe in recipes_with_product {
                    found = true;
                    *time += recipe.energy_required * parent_amt
                        / *recipe.results.get(ingredient).unwrap() as f64;
                    /*println!(
                        "Added {}s for {}",
                        recipe.energy_required * parent_amt
                            / *recipe.results.get(ingredient).unwrap() as f64,
                        recipe.name,
                    );*/

                    for (ing, req_amt) in &recipe.ingredients {
                        recurse_ingredient(
                            recipes,
                            ing,
                            *req_amt as f64 * parent_amt
                                / *recipe.results.get(ingredient).unwrap() as f64,
                            expensive,
                            tco,
                            time,
                        );
                    }
                }
            }
        }
    }
    if !found {
        let entry = tco.entry(ingredient.to_owned()).or_insert(0f64);
        *entry += parent_amt as f64;
    }
}
