# nvim-sort-dart-imports
Sort Dart imports in an organized way

It sorts imports by the following order:
```
dart imports

package imports

current package imports

relative imports

exports

part statements
```

## Installation
### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'f-person/nvim-sort-dart-imports'
```

## Usage
#### Sort Dart imports
```vim
:DartSortImports
```

#### Automatically sort Dart imports on save
```vim
autocmd FileType dart au BufWrite *dart :DartSortImports
```

## Demo
![demo](assets/demo.gif?raw=true)

Inspired by [Dart Data Class Generator](https://github.com/bnxm/Dart-Data-Class-Generator) [VS Code extension](https://marketplace.visualstudio.com/items?itemName=BendixMa.dart-data-class-generator)
