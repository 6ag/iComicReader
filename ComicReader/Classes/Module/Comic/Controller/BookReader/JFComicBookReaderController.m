//
//  JFComicBookReaderController.m
//  ComicReader
//
//  Created by Mr_J on 16/5/2.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "JFComicBookReaderController.h"
#import "JFComicShowImageContentCell.h"
#import "JFComicReaderBookModel.h"

@interface JFComicBookReaderController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GADInterstitialDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *contentCollectionView;

@property (nonatomic, strong) JFComicReaderBookModel *contentModel;
@property(nonatomic, strong) GADInterstitial *interstitial;

@end

static NSString *cellIdentifier = @"JFComicShowImageContentCellIdentifier";
@implementation JFComicBookReaderController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self requestData];
    [self initSubViews];
    self.interstitial = [self createAndLoadInterstitial];
    
    // 添加横幅广告
//    [self.view addSubview:[self createBannerView]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTappedContentView:)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

/**
 *  创建横幅广告
 */
- (GADBannerView *)createBannerView {
    GADBannerView *bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
    bannerView.frame = CGRectMake(0, kScreenHeight - 50, kScreenWidth, 50);
    bannerView.rootViewController = self;
    bannerView.adUnitID = @"ca-app-pub-3941303619697740/8007370512";
    [bannerView loadRequest:[GADRequest request]];
    return bannerView;
}

/**
 *  创建插页广告
 */
- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial = [[GADInterstitial alloc] initWithAdUnitID:@"ca-app-pub-3941303619697740/9484103714"];
    interstitial.delegate = self;
    [interstitial loadRequest:[GADRequest request]];
    return interstitial;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitial = [self createAndLoadInterstitial];
}

- (void)initSubViews{
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.contentCollectionView.collectionViewLayout;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    self.contentCollectionView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
    [self.contentCollectionView registerNib:[UINib nibWithNibName:@"JFComicShowImageContentCell" bundle:nil] forCellWithReuseIdentifier:cellIdentifier];
}

- (void)didTappedContentView:(UITapGestureRecognizer *)tag {
    
    if ([self.interstitial isReady]) {
        [self.interstitial presentFromRootViewController:self];
    }
    
    BOOL alpha = [UIApplication sharedApplication].statusBarHidden;
    [UIView animateWithDuration:0.25 animations:^{
        [[UIApplication sharedApplication] setStatusBarHidden:!alpha withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setNavigationBarHidden:!alpha animated:YES];
    }];
}

- (void)requestData{
    if (!_bookID) {
        [KVNProgress showErrorWithParameters:@{KVNProgressViewParameterStatus: @"未找到相关漫画!",
                                               KVNProgressViewParameterFullScreen: @(NO)}];
        return;
    }
    NSString *headerURLString = @"http://api.kuaikanmanhua.com/v1/comics/";
    NSString *urlString = [NSString stringWithFormat:@"%@%@", headerURLString, _bookID];
    
    __unsafe_unretained typeof(self) p = self;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        p.contentModel = [[JFComicReaderBookModel alloc]initWithDictionary:responseObject[@"data"]];
        self.title = p.contentModel.title;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [KVNProgress showErrorWithParameters:@{KVNProgressViewParameterStatus: @"网络不给力！",
                                               KVNProgressViewParameterFullScreen: @(NO)}];
    }];
}

- (void)setContentModel:(JFComicReaderBookModel *)contentModel{
    _contentModel = contentModel;
    [self.contentCollectionView reloadData];
}

#pragma mark - delegate
#pragma mark collection
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    [collectionView.collectionViewLayout invalidateLayout];
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _contentModel.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    JFComicShowImageContentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    JFComicReaderBookContentModel *model = _contentModel.images[indexPath.row];
    [cell.contentImageView sd_setImageWithURL:[NSURL URLWithString:model.cover_image_url]
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
     {
         if (image) {
             model.contentHeight = @((kScreenWidth) / image.size.width * image.size.height);
             [CATransaction begin];
             [CATransaction setDisableActions:YES];
             [collectionView reloadItemsAtIndexPaths:@[indexPath]];
             [CATransaction commit];
         }
     }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat height = ((kScreenWidth / 1.5) * (kScreenWidth / 1.1782)) / kScreenWidth;
    JFComicReaderBookContentModel *model = _contentModel.images[indexPath.row];
    if (model.contentHeight) {
        height = model.contentHeight.floatValue;
    }
    return CGSizeMake(kScreenWidth, height);
}

@end
